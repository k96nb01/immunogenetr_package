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
#' # The HLA_typing_LIS dataset contains a table as might be found in a clinical
#' # laboratory information system:
#' print(HLA_typing_LIS)
#'
#' # The `HLA_prefix_add` function can be used to add the correct HLA prefixes to the table:
#' library(dplyr)
#' HLA_typing_LIS %>% mutate(
#'   across(
#'     mA1Cd.recipient:mA2Cd.recipient,
#'     ~ HLA_prefix_add(., "HLA-A*")
#'   )
#' )
#'
#' @export
#'
#' @importFrom stringr str_replace

HLA_prefix_add <- function(data, prefix = "HLA-") {
  # Add string to beginning of typing
  str_replace(data, "^", prefix)
}
