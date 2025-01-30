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
#' df <- data.frame(
#'   A1 = c("HLA-A2", "A2", "A*11:01", "A66", "HLA-DRB3*15:01"),
#'   A2 = c("HLA-A1", "A1", "A*02:01", "A68", "HLA-DRB4*14:01"),
#'   stringsAsFactors = FALSE
#' )
#'
#' df$A1 <- HLA_prefix_remove(df$A1)
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

