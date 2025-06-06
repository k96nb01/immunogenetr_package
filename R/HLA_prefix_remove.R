#' @title HLA_prefix_remove
#'
#' @description This function removes HLA and optionally locus prefixes from a string of HLA typing:
#' "HLA-A2" changes to "A2" or "2". By default, HLA and locus prefixes are removed. This function
#' also works on each allele in a GL string.
#'
#' @param data A string with a single HLA allele, a GL string of HLA alleles,
#' or a character vector containing either of the previous.
#'
#' @return A vector modified to remove HLA and optionally locus prefixes.
#'
#' @examples
#' # The HLA_typing_1 dataset contains a table with HLA typing spread across multiple columns:
#' print(HLA_typing_1)
#'
#' # The `HLA_prefix_remove` function can be used to get each column to have only the
#' # colon-separated fields:
#' library(dplyr)
#' HLA_typing_1 %>% mutate(
#'   across(
#'     A1:DPB1_2,
#'     ~ HLA_prefix_remove(.)
#'   )
#' )
#'
#' @export
#'
#' @importFrom dplyr %>%
#' @importFrom dplyr mutate
#' @importFrom stringr str_replace

HLA_prefix_remove <- function(data, keep_locus = FALSE) {
  # Removes any HLA and locus prefixes from typing results.
  step_1 <- data %>%
    GLstring_expand_longer() %>%
    # replaces "HLA-" with an empty string in each cell.
    mutate(value = str_replace(value, "HLA-", ""))

  if (keep_locus) {
    step_2 <- step_1
  } else {
    # Remove the locus.
    step_2 <- step_1 %>%
      # replaces any sequences of alphabetic characters at the start of the string with an empty string
      mutate(value = str_replace(value, "^[:alpha:]+", "")) %>%
      # replaces any sequences of digits followed by an asterisk with an empty string
      mutate(value = str_replace(value, "[:digit:]*\\*", ""))
  }

  # Reassemble the GL string
  ambiguity_table_to_GLstring(step_2)
}

globalVariables(c("step_1", "step_2"))
