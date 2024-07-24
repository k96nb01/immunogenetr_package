#' @title HLA_prefix_add
#'
#' @description This function adds a specified prefix to the beginning of
#' each value in the identified columns of the given data frame.
#'
#' @param .data A data frame
#' @param columns Name of columns in .data to which the prefix should be added
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
#' # Add HLA- prefix to columns A1 and A2
#' df %>% HLA_prefix_add(columns = c("A1", "A2"))
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr %>%
#' @importFrom stringr str_replace
#' @importFrom stringr str_interp

HLA_prefix_add <- function(.data, columns, prefix = "HLA-") {
  # Add string to beginning of typing
  .data %>% mutate(across({{ columns }}, ~str_replace(., "^", str_interp('${ prefix }'))))
}
