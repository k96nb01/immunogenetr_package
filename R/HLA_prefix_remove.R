#' @title HLA_prefix_remove
#'
#' @description This function removes HLA and optionally locus prefixes from a string of HLA typing:
#' "HLA-A2" changes to "A2" or "2". By default, HLA and locus prefixes are removed. This function
#' also works on each allele in a GL string.
#'
#' @param data A string with a single HLA allele, a GL string of HLA alleles,
#' or a character vector containing either of the previous.
#' @param keep_locus A logical value indicating whether to retain any locus values.
#' The default value is FALSE.
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
  # Validate inputs
  check_gl_string(data, "data")
  check_logical_flag(keep_locus, "keep_locus")

  # Removes any HLA and locus prefixes from typing results.
  result <- data %>%
    GLstring_expand_longer() %>%
    # Remove "HLA-" prefix from each allele.
    mutate(value = str_replace(value, "HLA-", ""))

  if (!keep_locus) {
    # Remove locus prefix in two passes:
    # Pass 1: Remove alphabetic prefix anchored at the start (e.g. "DRB" from "DRB1*04:01", "A" from "A2").
    # Pass 2: Remove any remaining digits followed by an asterisk (e.g. "1*" from "1*04:01").
    # These cannot be combined because pass 2 must be unanchored to catch the asterisk
    # after pass 1 has already stripped the alpha characters.
    result <- result %>%
      mutate(value = str_replace(value, "^[:alpha:]+", "")) %>%
      mutate(value = str_replace(value, "[:digit:]*\\*", ""))
  }

  # Reassemble the GL string.
  ambiguity_table_to_GLstring(result)
}
