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
#' @param serologic Whether the final type should be formatted in serologic resolution;
#' molecular resolution is the default.
#'
#' @return A list of GL strings in the order of the original data frame.
#'
#' @examples
#' typing_table <- tibble(
#' patient = c("patient1", "patient2", "patient3"),
#' mA1cd = c("A*01:01", "A*02:01", "A*03:01"),
#' mA2cd = c("A*11:01", "blank", "A*26:01"),
#' mB1cd = c("B*07:02", "B*08:01", "B*15:01"),
#' mB2cd = c("B*44:02", "B*40:01", "-"),
#' mC1cd = c("C*03:04", "C*04:01", "C*05:01"),
#' mC2cd = c("C*07:01", "C*07:02", "C*08:01")
#' )
#'
#' typing_table %>% mutate(GL_string = HLA_columns_to_GLstring(., HLA_typing_columns = c(mA1cd:mC2cd), prefix_to_remove = "m", suffix_to_remove = "cd"))
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr %>%
#' @importFrom dplyr select
#' @importFrom dplyr case_when
#' @importFrom dplyr if_else
#' @importFrom dplyr coalesce
#' @importFrom dplyr filter
#' @importFrom dplyr distinct
#' @importFrom dplyr pull
#' @importFrom dplyr summarise
#' @importFrom stringr str_c
#' @importFrom stringr str_escape
#' @importFrom stringr str_replace
#' @importFrom stringr str_detect
#' @importFrom stringr str_to_upper
#' @importFrom stringr str_glue
#' @importFrom stringr str_flatten
#' @importFrom tidyr pivot_longer
#' @importFrom tidyselect all_of
#' @importFrom cli format_error

HLA_columns_to_GLstring <- function(data, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "", serologic = FALSE) {
  # Set up prefix and suffix regex to remove unwanted parts
  prefix_regex <- regex(str_c("^", str_escape(prefix_to_remove)), ignore_case = TRUE)
  suffix_regex <- regex(str_c(str_escape(suffix_to_remove), "$"), ignore_case = TRUE)

  # Identify the columns to modify
  col2mod <- names(select(data, {{HLA_typing_columns}}))

  # Processing Step 1
  step1 <- data %>%
    mutate(row_for_function = 1:nrow(.)) %>%
    pivot_longer(cols = all_of(col2mod), names_to = "names", values_to = "allele") %>%
    # Remove prefixes and suffixes from column names
    mutate(truncated_names = str_replace(names, prefix_regex, ""),
           truncated_names = str_replace(truncated_names, suffix_regex, "")) %>%
    # Validate alleles and remove blanks
    mutate(allele = HLA_validate(allele)) %>%
    filter(!is.na(allele)) %>%
    # Determine locus name using extended logic
    mutate(locus_from_name = case_when(
      str_detect(truncated_names, regex("^[Aa]([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-A",  # Handle A locus
      str_detect(truncated_names, regex("^[Bb]([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-B",  # Handle B locus
      str_detect(truncated_names, regex("^Bw([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-Bw",  # Handle Bw separately from B locus
      str_detect(truncated_names, regex("^[Cc][Ww]?([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-Cw",  # Handle Cw locus
      str_detect(truncated_names, regex("^[Dd][Rr][Ww]?([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-DR",  # Handle DR locus
      str_detect(truncated_names, regex("^[Dd][Qq]([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-DQ",  # Corrected for DQ locus in serologic typing
      str_detect(truncated_names, regex("^mDQA1[12]?([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-DQA1",  # Molecular DQA1
      str_detect(truncated_names, regex("^mDPA1[12]?([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-DPA1",  # Molecular DPA1
      str_detect(truncated_names, regex("^mDPB1[12]?([0-9]*)?$", ignore_case = TRUE)) ~ "HLA-DPB1",  # Molecular DPB1
      TRUE ~ "unknown"
    )) %>%
    # Rename "CW" to "Cw" for standardization
    mutate(locus_from_name = str_replace(locus_from_name, "HLA-CW", "HLA-Cw")) %>%
    # Handle the final locus name for high-resolution DRB alleles
    mutate(DRB_locus = if_else(
      str_detect(locus_from_name, "DRB"), str_c("HLA-DRB", str_extract(allele, "[1345](?=\\*)")), NA_character_
    )) %>%
    # Determine the final locus name
    mutate(final_locus = coalesce(DRB_locus, locus_from_name)) %>%
    # Handle serologic typing but skip for molecular loci
    mutate(allele = if_else(
      serologic & !str_detect(final_locus, "DQA1|DQB|DPA1|DPB1|DQ"),  # Avoid modifying molecular notations
      str_replace(allele, ".+\\*", ""),  # Remove prefix before asterisk for serologic types
      allele
    )) %>%
    # Correct the molecular notation for DQA1, DPA1, DPB1 loci when serologic = TRUE
    mutate(allele = if_else(
      str_detect(final_locus, "DQA1|DPA1|DPB1"),
      str_replace(allele, "(\\d+):(\\d+):(\\d+)", "*\\1:\\2:\\3"),  # Ensure molecular format with '*'
      allele
    ))

  # Set up error detection for any loci that could not be determined
  error_table <- step1 %>% filter(locus_from_name == "unknown")
  error_column_names <- error_table %>% select(names) %>% distinct() %>% dplyr::pull(names)

  if (nrow(error_table) != 0) {
    # Print the columns that caused the error to assist in debugging
    print(glue::glue("Columns that could not be parsed: {paste(error_column_names, collapse = ', ')}"))
    abort(format_error("The column(s) {paste(error_column_names, collapse = ', ')} could not be parsed to determine HLA loci."))
  }

  # Assemble the final type
  step2 <- step1 %>%
    mutate(final_type = str_glue("{final_locus}{allele}")) %>%
    # Group alleles within the same locus
    summarise(final_type_2 = str_flatten(final_type, collapse = "+"), .by = c(row_for_function, locus_from_name)) %>%
    # Assemble GL string with each locus separated by "^"
    summarise(GL_string = str_flatten(final_type_2, collapse = "^"), .by = c(row_for_function))

  # Return GL Strings
  return(step2 %>% dplyr::pull(GL_string))
}
