#' @title HLA_prefix_remove
#'
#' @description This function removes HLA and locus prefixes from a string of HLA typing:
#' "HLA-A2" changes to "2".
#'
#' @param data A string with a single HLA allele.
#'
#' @return A string modified to remove HLA and locus prefixes.
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
#' @importFrom stringr str_replace

HLA_prefix_remove <- function(data) {
  # Removes any HLA and locus prefixes from typing results.
  data %>%
    # replaces "HLA-" with an empty string in each cell.
    str_replace("HLA-", "") %>%
    # replaces any sequences of alphabetic characters at the start of the string with an empty string
    str_replace("^[:alpha:]+", "") %>%
    # replaces any sequences of digits followed by an asterisk with an empty string
    str_replace(., "[:digit:]*\\*", "")
}

globalVariables(c("."))
