#' @title HLA_prefix_remove
#'
#' @description This function removes HLA and locus prefixes from typing
#' results in specified columns of a data frame. For example, a column with
#' values `c("HLA-A2", "A2", "A*11:01", "A66", "HLA-DRB3*15:01")` changes to
#' `c("2", "2", "11:01", "66", "15:01")`
#'
#' @param .data A data frame
#' @param columns Names of columns in .data containing HLA typing results
#'
#' @return A data frame object with specified columns modified to remove HLA
#' and locus prefixes.
#'
#' @examples
#' data(toydata)
#' output <- toydata %>% HLA_prefix_remove(A.2_recipient)
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr %>%
#' @importFrom stringr str_replace

HLA_prefix_remove <- function(.data, columns) {
  # Removes any HLA and locus prefixes from typing results.
  .data %>%
    mutate(across({{ columns }}, ~str_replace(., "HLA-", ""))) %>%
    # replaces "HLA-" with an empty string in each cell.
    mutate(across({{ columns }}, ~str_replace(., "[:alpha:]+", ""))) %>%
    # replaces any sequences of alphabetic characters with an empty string
    mutate(across({{ columns }}, ~str_replace(., "[:digit:]*\\*", "")))
    # replaces any sequences of digits followed by an asterisk with an empty string
}
