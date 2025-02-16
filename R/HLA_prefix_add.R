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
#' df <- data.frame(
#'   A1 = c("01:01", "02:01"),
#'   A2 = c("03:01", "11:01"),
#'   B1 = c("07:02", "08:01"),
#'   B2 = c("15:01", "44:02"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Add "HLA-A*" prefix to columns A1 and A2
#' df$A1 <- HLA_prefix_add(df$A1, "HLA-A*")
#' df$A2 <- HLA_prefix_add(df$A2, "HLA-A*")
#'
#' @export
#'
#' @importFrom stringr str_replace

HLA_prefix_add <- function(data, prefix = "HLA-") {
  # Add string to beginning of typing
  str_replace(data, "^", prefix)
}
