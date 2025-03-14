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
#'   mutate(GL_string = HLA_columns_to_GLstring(
#'     ., # Note that if this function is used inside a `mutate` call "." will have to be
#'     # used as the first argument to extract data from the working data frame.
#'     HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'     prefix_to_remove = "m",
#'     suffix_to_remove = "Cd.recipient"
#'   ),
#'   .after = patient) %>%
#'   select(patient, GL_string)
#'
#' # Using the base pipe:
#' HLA_typing_LIS |>
#'   mutate(GL_string = HLA_columns_to_GLstring(
#'     HLA_typing_LIS, # If using the base pipe, the first argument will have to be
#'     # the working data frame.
#'     HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'     prefix_to_remove = "m",
#'     suffix_to_remove = "Cd.recipient"
#'   ),
#'   .after = patient) |>
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
#' @importFrom cli format_error
#' @importFrom rlang abort

HLA_columns_to_GLstring <- function(data, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "") {
  # Set up prefix and suffix regex to remove unwanted parts
  prefix_regex <- regex(str_c("^", str_escape(prefix_to_remove)), ignore_case = TRUE)
  suffix_regex <- regex(str_c(str_escape(suffix_to_remove), "$"), ignore_case = TRUE)

  # Identify the columns to modify
  col2mod <- names(select(data, {{ HLA_typing_columns }}))

  # Processing Step 1
  step1 <- data %>%
    mutate(row_for_function = row_number()) %>%
    # pivoting longer to get each allele on a separate row.
    pivot_longer(cols = all_of(col2mod), names_to = "names", values_to = "allele") %>%
    # Determine if typing is molecular by presence of ":" in allele, a leading zero, or the loci DQA1, DPB1, and DPA1, which are always in molecular format.
    mutate(molecular = str_detect(allele, ":") | str_detect(allele, "^0") | str_detect(names, "(DQA1)|(DPB1)|(DPA1)")) %>%
    # Remove prefixes and suffixes from column names
    mutate(
      truncated_names = str_replace(names, prefix_regex, ""),
      truncated_names = str_replace(truncated_names, suffix_regex, "")
    ) %>%
    # Use the HLA_validate function to clean up the typing
    mutate(allele = HLA_validate(allele)) %>%
    # Remove any prefixes in alleles
    mutate(allele = HLA_prefix_remove(allele)) %>%
    # Determine locus name using extended logic
    mutate(locus_from_name = case_when(
      str_detect(truncated_names, regex("^A[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-A", # Handle A locus
      str_detect(truncated_names, regex("^Bw[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-Bw", # Handle Bw separately from B locus
      str_detect(truncated_names, regex("^B[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-B", # Handle B locus
      str_detect(truncated_names, regex("^Cw[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-Cw", # Handle Cw locus
      str_detect(truncated_names, regex("^C[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-C", # Handle C locus
      str_detect(truncated_names, regex("^DRB1[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DRB1", # Handle molecular DRB1 locus
      str_detect(truncated_names, regex("^DRB3[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DRB3", # Handle molecular DRB3 locus
      str_detect(truncated_names, regex("^DRB4[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DRB4", # Handle molecular DRB4 locus
      str_detect(truncated_names, regex("^DRB5[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DRB5", # Handle molecular DRB5 locus
      str_detect(truncated_names, regex("^DRw?[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DR", # Handle serologic DR locus
      str_detect(truncated_names, regex("^DQB1[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DQB1", # Handle molecular DQB1 locus
      str_detect(truncated_names, regex("^DQA1[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DQA1", # Molecular DQA1
      str_detect(truncated_names, regex("^DQ[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DQ", # Handle serologic DQ locus
      str_detect(truncated_names, regex("^DPA1[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DPA1", # Molecular DPA1
      str_detect(truncated_names, regex("^DPB1[:digit:]?\\*?", ignore_case = TRUE)) ~ "HLA-DPB1", # Molecular DPB1
      TRUE ~ "unknown"
    )) %>%
    # Determine serologic locus names
    mutate(serologic_name = case_when(
      locus_from_name == "HLA-A" ~ "HLA-A",
      locus_from_name == "HLA-B" ~ "HLA-B",
      locus_from_name == "HLA-Bw" ~ "HLA-Bw",
      str_detect(locus_from_name, "HLA-C[Ww]?") ~ "HLA-Cw",
      str_detect(locus_from_name, "DR") ~ "HLA-DR",
      locus_from_name == "HLA-DQA1" ~ "HLA-DQA",
      str_detect(locus_from_name, "HLA-DQ") ~ "HLA-DQ",
      locus_from_name == "HLA-DPA1" ~ "HLA-DPA",
      locus_from_name == "HLA-DPB1" ~ "HLA-DP",
      TRUE ~ "unknown"
    )) %>%
    # Determine if the DR typing is one of the DR51/52/53 loci
    mutate(DRB345 = if_else(str_detect(allele, "^5") & locus_from_name == "HLA-DR", TRUE, FALSE)) %>%
    # Handle the final locus name for high-resolution DRB alleles
    mutate(DRB_locus = if_else(
      str_detect(locus_from_name, "DRB"), str_c("HLA-DRB", str_extract(allele, "[1345](?=\\*)")), NA_character_
    )) %>%
    # Determine the final molecular locus name
    mutate(molecular_locus = coalesce(DRB_locus, locus_from_name)) %>%
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
    print(glue::glue("Columns that could not be parsed: {paste(error_column_names, collapse = ', ')}"))
    abort(format_error("The column(s) {paste(error_column_names, collapse = ', ')} could not be parsed to determine HLA loci."))
  }

  # Assemble the final type
  step2 <- step1 %>%
    mutate(final_type = if_else(
      molecular,
      str_glue("{molecular_locus}*{allele}"),
      str_glue("{serologic_name}{allele}")
    )) %>%
    # Group alleles within the same locus
    summarise(final_type_2 = str_flatten(final_type, collapse = "+"), .by = c(row_for_function, locus_from_name, DRB345)) %>%
    # Assemble GL string with each locus separated by "^"
    summarise(GL_string = str_flatten(final_type_2, collapse = "^"), .by = row_for_function)

  # Return GL Strings
  return(step2 %>% dplyr::pull(GL_string))
}

globalVariables(c(
  ".", "truncated_names", "locus_from_name", "DRB_locus",
  "row_for_function", "molecular_locus", "molecular",
  "final_type", "DRB345", "final_type_2", "GL_string"
))
