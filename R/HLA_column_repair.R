#' @title HLA_column_repair
#'
#' @description This function will change column names that have the official
#'  HLA nomenclature (e.g. "HLA-A*" or "HLA-A") to a format supported by R
#'  (e.g. "HLA_A"). The dash and asterisk are a special characters in R,
#'  and makes selecting columns by name difficult.
#'
#' @param data A data frame
#'
#' @return A data frame object with column names renamed in the "HLA_A" format.
#'
#' @examples
#' data(toydata) # I think we need to make some toydata.
#' output <- HLA_column_repair(toydata)
#' @export
#' @importFrom dplyr "%>%"

HLA_column_repair <- function(data, format = "tidyverse") {
  data %>%
    rename_with(~ str_replace(., "HLA\\-", "HLA_")) %>%
    rename_with(~ str_replace(., "\\*$", ""))
}

