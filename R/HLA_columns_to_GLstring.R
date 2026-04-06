#' @title HLA_columns_to_GLstring
#'
#' @description A function to take HLA typing data spread across different columns,
#' as is often found in wild-caught data, and transform it to a GL string. If column names
#' have anything besides the locus name and a number (e.g. "mA1Cd" instead of just "A1"),
#' the function will have trouble determining the locus from the column name. The `prefix_to_remove`
#' and `suffix_to_remove` arguments can be used to clean up the column names. See the example for
#' how these arguments are used.
#'
#' @param data A data frame with each row including an HLA typing result, with
#' individual columns containing a single allele.
#' @param HLA_typing_columns A list of columns containing the HLA alleles. Tidyselect is supported.
#' @param prefix_to_remove An optional string of characters to remove from the
#' locus names. The goal is to get the column names to the locus and a number. For example,
#' columns named "mDRB11Cd" and "mDRB12Cd" should use the `prefix_to_remove` value of "m".
#' @param suffix_to_remove An optional string of characters to remove from the
#' locus names. Using the example above, the `suffix_to_remove` value will be "Cd".
#'
#' @return A list of GL strings in the order of the original data frame.
#'
#' @examples
#' # The HLA_typing_LIS dataset contains a table as might be found in a clinical laboratory
#' # information system:
#' print(HLA_typing_LIS)
#'
#' # The `HLA_columns_to_GLString` function can be used to coerce typing spread across
#' # multiple columns into a GL string:
#' library(dplyr)
#' HLA_typing_LIS %>%
#'   mutate(
#'     GL_string = HLA_columns_to_GLstring(
#'       ., # Note that if this function is used inside a `mutate` call "." will have to be
#'       # used as the first argument to extract data from the working data frame.
#'       HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'       prefix_to_remove = "m",
#'       suffix_to_remove = "Cd.recipient"
#'     ),
#'     .after = patient
#'   ) %>%
#'   select(patient, GL_string)
#'
#' # Using the base pipe:
#' HLA_typing_LIS |>
#'   mutate(
#'     GL_string = HLA_columns_to_GLstring(
#'       HLA_typing_LIS, # If using the base pipe, the first argument will have to be
#'       # the working data frame.
#'       HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'       prefix_to_remove = "m",
#'       suffix_to_remove = "Cd.recipient"
#'     ),
#'     .after = patient
#'   ) |>
#'   select(patient, GL_string)
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr %>%
#' @importFrom dplyr select
#' @importFrom dplyr case_when
#' @importFrom dplyr if_else
#' @importFrom dplyr coalesce
#' @importFrom dplyr filter
#' @importFrom dplyr distinct
#' @importFrom dplyr pull
#' @importFrom dplyr summarise
#' @importFrom glue glue
#' @importFrom stringr regex
#' @importFrom stringr str_c
#' @importFrom stringr str_escape
#' @importFrom stringr str_extract
#' @importFrom stringr str_replace
#' @importFrom stringr str_detect
#' @importFrom stringr str_glue
#' @importFrom stringr str_flatten
#' @importFrom tidyr pivot_longer
#' @importFrom tidyselect all_of
#' @importFrom cli cli_abort

HLA_columns_to_GLstring <- function(data, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "") {
  # Validate inputs
  check_data_frame(data, "data")

  # Set up prefix and suffix regex to remove unwanted parts
  prefix_regex <- regex(str_c("^", str_escape(prefix_to_remove)), ignore_case = TRUE)
  suffix_regex <- regex(str_c(str_escape(suffix_to_remove), "$"), ignore_case = TRUE)

  # Identify the columns to modify
  col2mod <- names(select(data, {{ HLA_typing_columns }}))

  # Named vector mapping molecular locus names to their serologic equivalents.
  # Used as a fast lookup instead of a case_when with str_detect calls.
  serologic_map <- c(
    "HLA-A" = "HLA-A",
    "HLA-B" = "HLA-B",
    "HLA-Bw" = "HLA-Bw",
    "HLA-C" = "HLA-Cw",
    "HLA-Cw" = "HLA-Cw",
    "HLA-DRB1" = "HLA-DR",
    "HLA-DRB345" = "HLA-DR",
    "HLA-DRB3" = "HLA-DR",
    "HLA-DRB4" = "HLA-DR",
    "HLA-DRB5" = "HLA-DR",
    "HLA-DR" = "HLA-DR",
    "HLA-DQB1" = "HLA-DQ",
    "HLA-DQA1" = "HLA-DQA",
    "HLA-DQ" = "HLA-DQ",
    "HLA-DPA1" = "HLA-DPA",
    "HLA-DPB1" = "HLA-DP",
    "unknown" = "unknown"
  )

  # Processing Step 1
  step1 <- data %>%
    mutate(row_for_function = row_number()) %>%
    # Pivoting longer to get each allele on a separate row.
    pivot_longer(cols = all_of(col2mod), names_to = "names", values_to = "allele") %>%
    # Determine if typing is molecular by presence of ":" or leading zero in allele,
    # or the loci DQA1, DPB1, and DPA1, which are always in molecular format.
    mutate(molecular = str_detect(allele, ":|^0") | str_detect(names, "DQA1|DPB1|DPA1")) %>%
    # Remove prefixes and suffixes from column names.
    mutate(
      truncated_names = str_replace(names, prefix_regex, ""),
      truncated_names = str_replace(truncated_names, suffix_regex, ""),
      truncated_names = HLA_prefix_remove(truncated_names, keep_locus = TRUE)
    ) %>%
    # Use the HLA_validate function to clean up the typing.
    mutate(allele = HLA_validate(allele)) %>%
    # Determine if allele itself specifies a DRB3/4/5 locus (for generic DRB345 columns).
    mutate(
      DRB_locus_raw = case_when(
        # When the allele starts with "DRB3*", "DRB4*" or "DRB5*"
        str_detect(allele, regex("DRB[345]\\*", ignore_case = TRUE)) ~ str_c("HLA-DRB", str_extract(allele, "(?<=DRB)[345]")),
        # When the allele does not have a "DRB" prefix, instead only has a number prefix
        str_detect(allele, regex("^[345]\\*", ignore_case = TRUE)) ~ str_c("HLA-DRB", str_extract(allele, "^[345]")),
        TRUE ~ NA_character_
      )
    ) %>%
    # Remove any prefixes in alleles.
    mutate(allele = HLA_prefix_remove(allele)) %>%
    # Lowercase column names once for case-insensitive prefix matching.
    mutate(lower_names = tolower(truncated_names)) %>%
    # Determine locus name from column name using prefix matching.
    # Order matters: more specific prefixes must come before less specific ones
    # (e.g. "bw" before "b", "drb345" before "drb3", "dqb1" before "dq").
    mutate(locus_from_name = case_when(
      startsWith(lower_names, "a") ~ "HLA-A",
      startsWith(lower_names, "bw") ~ "HLA-Bw",
      startsWith(lower_names, "b") ~ "HLA-B",
      startsWith(lower_names, "cw") ~ "HLA-Cw",
      startsWith(lower_names, "c") ~ "HLA-C",
      startsWith(lower_names, "drb345") ~ "HLA-DRB345",
      startsWith(lower_names, "drb1") ~ "HLA-DRB1",
      startsWith(lower_names, "drb3") ~ "HLA-DRB3",
      startsWith(lower_names, "drb4") ~ "HLA-DRB4",
      startsWith(lower_names, "drb5") ~ "HLA-DRB5",
      startsWith(lower_names, "dr") ~ "HLA-DR",
      startsWith(lower_names, "dqb1") ~ "HLA-DQB1",
      startsWith(lower_names, "dqa1") ~ "HLA-DQA1",
      startsWith(lower_names, "dq") ~ "HLA-DQ",
      startsWith(lower_names, "dpa1") ~ "HLA-DPA1",
      startsWith(lower_names, "dpb1") ~ "HLA-DPB1",
      TRUE ~ "unknown"
    )) %>%
    # Look up the serologic name from the molecular locus name.
    mutate(serologic_name = serologic_map[locus_from_name]) %>%
    # Determine if the DR typing is one of the DR51/52/53 loci.
    mutate(DRB345 = if_else(str_detect(allele, "^5") & locus_from_name == "HLA-DR", TRUE, FALSE)) %>%
    # Handle the final locus name for high-resolution DRB alleles.
    mutate(molecular_locus = coalesce(DRB_locus_raw, locus_from_name)) %>%
    # Record "XX" if there is no typing at any of the selected loci.
    mutate(allele = if (all(is.na(allele))) "XX" else allele, .by = c(row_for_function, molecular_locus)) %>%
    # Remove any blank values
    filter(!is.na(allele)) %>%
    # Remove any "XX" values from the DRB3/4/5 loci
    filter(!(allele == "XX" & str_detect(molecular_locus, "DRB[345]")))

  # Set up error detection for any loci that could not be determined
  error_table <- step1 %>% filter(locus_from_name == "unknown")
  error_column_names <- error_table %>%
    select(names) %>%
    distinct() %>%
    dplyr::pull(names)

  if (nrow(error_table) != 0) {
    # Print the columns that caused the error to assist in debugging
    cli_abort("The column(s) {.val {error_column_names}} could not be parsed to determine HLA loci.")
  }

  # Assemble the final type
  step2 <- step1 %>%
    mutate(final_type = if_else(
      molecular,
      str_glue("{molecular_locus}*{allele}"),
      str_glue("{serologic_name}{allele}")
    )) %>%
    # Group alleles within the same locus
    summarise(final_type_2 = str_flatten(final_type, collapse = "+"), .by = c(row_for_function, molecular_locus, DRB345)) %>%
    # Assemble GL string with each locus separated by "^"
    summarise(GL_string = str_flatten(final_type_2, collapse = "^"), .by = row_for_function)

  # Return GL Strings
  return(step2 %>% dplyr::pull(GL_string))
}

globalVariables(c(
  ".", "truncated_names", "lower_names", "locus_from_name", "DRB_locus",
  "row_for_function", "molecular_locus", "molecular", "serologic_name",
  "final_type", "DRB345", "final_type_2", "GL_string", "DRB_locus_raw"
))
