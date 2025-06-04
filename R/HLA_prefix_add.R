#' @title HLA_prefix_add
#'
#' @description This function adds a specified prefix to the beginning of
#' each HLA type, and works on a single allele or all alleles in a GL string.
#' Useful for adding HLA or gene prefixes.
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
#' @importFrom dplyr mutate
#' @importFrom dplyr %>%

HLA_prefix_add <- function(data, prefix = "HLA-") {
  # Expand the allele of GL string
  data %>%
    GLstring_expand_longer() %>%
    # Add string to beginning of typing
    mutate(value = str_replace(value, "^", prefix)) %>%
    # Collapse the GL string
    ambiguity_table_to_GLstring()
}
