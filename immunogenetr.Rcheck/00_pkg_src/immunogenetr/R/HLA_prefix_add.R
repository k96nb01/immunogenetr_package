#' @title HLA_prefix_add
#'
#' @description This function adds a specified prefix to the beginning of
#' each value in the identified columns of the given data frame. Useful for adding
#' HLA or gene prefixes.
#'
#' @param data A string with a single HLA allele.
#' @param prefix A character string to be added as a prefix to the column values.
#' Default is "HLA-".
#'
#' @return A data frame with the specified prefix added to the values in the
#' selected columns.
#'
#' @examples
#'
#' file <- HLA_typing_1[, -1]
#'
#' # Add "HLA-" prefix to columns A1 and A2
#' file$A1 <- HLA_prefix_add(file$A1, "HLA-")
#' file$A2 <- HLA_prefix_add(file$A2, "HLA-")
#'
#' @export
#'
#' @importFrom stringr str_replace

HLA_prefix_add <- function(data, prefix = "HLA-") {
  # Add string to beginning of typing
  str_replace(data, "^", prefix)
}
