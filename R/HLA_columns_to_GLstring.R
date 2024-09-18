#' @title HLA_columns_to_GLstring
#'
#' @description A function to take HLA typing data spread across different columns,
#' as is often found in wild-caught data, and transform it to a GL string.
#'
#' @param data A data frame with each row including an HLA typing result, with
#' individual columns containing a single allele.
#' @param case_column A column that uniquely identifies the typing result.
#' @param HLA_typing_columns The list of columns containing the HLA alleles.
#' @param prefix_to_remove An optional string of characters to remove from the
#' locus names.
#' @param suffix_to_remove An optional string of characters to remove from the
#' locus names.
#' @param serologic Whether the final type should be formatted in serologic resolution;
#' molecular resolution is the default.
#'
#' @return A list of GL strings in the order of the original data frame.
#'
#' @examples
#' df2 <- data.frame(
#'   patient = c("patient1", "patient2", "patient3"),
#'   A1 = c("A*01:01", "A*02:01", "A*03:01"),
#'   A2 = c("A*11:01", "A*24:02", "A*26:01"),
#'   B1 = c("B*07:02", "B*08:01", "B*15:01"),
#'   B2 = c("B*44:02", "B*40:01", "B*27:05"),
#'   C1 = c("C*03:04", "C*04:01", "C*05:01"),
#'   C2 = c("C*07:01", "C*07:02", "C*08:01"),
#'   stringsAsFactors = FALSE
#' )
#'
#' HLA_columns_to_GLstring(df2, case_column = "patient", HLA_typing_columns = c("A1", "A2", "B1", "B2", "C1", "C2"))
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

HLA_columns_to_GLstring <- function(data, case_column, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "", serologic = FALSE){
  # Set up prefix and suffix regex
  prefix <- str_c("^", str_escape(prefix_to_remove))
  suffix <- str_c(str_escape(suffix_to_remove), "$")
  # Identify the columns to modify
  col2mod <- names(select(data, {{HLA_typing_columns}}))

  step1 <- data %>%
    # pivoting longer to get each allele on a separate row.
    pivot_longer(cols = all_of(col2mod), names_to = "names", values_to = "allele") %>%
    # Remove any prefixes or suffixes from locus names
    mutate(trunctated_names = str_replace(names, regex(prefix, ignore_case = TRUE), "")) %>%
    mutate(trunctated_names = str_replace(trunctated_names, regex(suffix, ignore_case = TRUE), "")) %>%
    # Use the HLA_validate function to clean up the typing, and remove any blank values.
    mutate(allele = HLA_validate(allele)) %>%
    # Remove any blank (now NA) typing values.
    filter(!is.na(allele)) %>%
    # Determine the locus from the column names
    mutate(locus_from_name = case_when(
      str_detect(trunctated_names, "[Dd]") ~ str_c("HLA-", str_to_upper(str_extract(trunctated_names, "[Dd][PpQqRr]?[AaBb]?[:digit:]?"))),  #If the column was named "DRB345", for example, then all of the locus names will be "DRB3." Will have to extract names from allele to determine which locus.
      str_detect(trunctated_names, regex("TAP", ignore_case = TRUE)) ~ str_to_upper(str_extract(trunctated_names, "TAP[12]")),
      str_detect(trunctated_names, regex("HFE", ignore_case = TRUE)) ~ "HFE",
      str_detect(trunctated_names, regex("MIC", ignore_case = TRUE)) ~ str_to_upper(str_extract(trunctated_names, "MIC[AB]")),
      str_detect(trunctated_names, "(?<![LlQqPpRrCcTt])[Aa]") ~ "HLA-A",
      str_detect(trunctated_names, "(?<![QqPpRrCc])[Bb]") ~ "HLA-B",
      str_detect(trunctated_names, "(?<![QqPpRrIi])[Cc]") ~ str_c("HLA-", str_to_upper(str_extract(trunctated_names, "[Cc][Ww]?"))),
      str_detect(trunctated_names, "[EFGHJKLNPSTUVWYefghjklnpstuvwy]") ~ str_c("HLA-", str_to_upper(str_extract(trunctated_names, "[EFGHJKLNPSTUVWYefghjklnpstuvwy]"))),
      .default = "unknown"
    )) %>%
    # Rename any "CW" properly
    mutate(locus_from_name = str_replace(locus_from_name, "HLA-CW", "HLA-Cw")) %>%
    # Determine the DRB locus from the allele
    mutate(DRB_locus = if_else(
      str_detect(locus_from_name, "DRB"), str_c("HLA-DRB", str_extract(allele, "[1345](?=\\*)")), NA_character_
    )) %>%
    # Determine the final locus name from the two columns
    mutate(final_locus = coalesce(DRB_locus, locus_from_name)) %>%
    # Remove any info before the asterisk from the allele field
    mutate(allele = str_replace(allele, ".+\\*", ""))

  # Set up error detection for any loci that could not be determined
  error_table <- step1 %>% filter(locus_from_name == "unknown")
  error_column_names <- error_table %>% select(names) %>% distinct() %>% dplyr::pull(names)

  # Error code
  if (nrow(error_table) != 0) {
    abort(format_error("The  column(s) {error_column_names} could not be parsed to determine HLA loci."))
  }

  # Assemble the final type
  if (serologic == TRUE){
    step2 <- step1 %>% mutate(final_type = str_glue("{final_locus}{allele}", .na = ""))
  } else {
    step2 <- step1 %>% mutate(final_type = str_glue("{final_locus}*{allele}", .na = ""))
  }

  # Assemble the GL string
  step2 %>% summarise(final_type_2 = str_flatten(final_type, collapse = "+"), .by = c({{case_column}}, locus_from_name, DRB_locus)) %>%
    summarise(GL_string = str_flatten(final_type_2, collapse = "^"), .by = c({{case_column}})) %>% dplyr::pull(GL_string)
}
