#' @title HLA_validate
#'
#' @description Returns only HLA alleles in valid nomenclature, either serologic or molecular.
#' Simple numbers, such as "2" or "27" will be returned as-is. Suffixes that are not
#' WHO-recognized suffixes (L, S, C, A, Q, N) or G or P group designations will be removed.
#' For example "novel" at the end of the allele will be removed, while "n" at the end of the
#' allele will be retained. Other values, such as "blank" or "-" will be converted to NA values.
#' This function is helpful for cleaning up the typing of an entire table of HLA values.
#'
#'
#' @param data A string containing an HLA allele.
#'
#' @return A string with a valid HLA allele.
#'
#' @examples
#' HLA_validate("HLA-A2")
#' HLA_validate("A*02:01:01:01N")
#' HLA_validate("A*02:01:01N")
#' HLA_validate("HLA-DRB1*02:03novel")
#' HLA_validate("HLA-DQB1*03:01v")
#' HLA_validate("HLA-DRB1*02:03P")
#' HLA_validate("HLA-DPB1*04:01:01G")
#' HLA_validate("2")
#' HLA_validate(2)
#' HLA_validate("B27")
#' HLA_validate("A*010101")
#' HLA_validate("-")
#' HLA_validate("blank")
#'
#' @export
#'
#' @importFrom dplyr %>%
#' @importFrom stringr str_extract

HLA_validate <- function(data) {
  data %>%
    str_extract("(HLA-)?([:alnum:]*)(\\*)?[:digit:]{1,}:?[:digit:]*:?[:digit:]*:?[:digit:]*([GPLSCAQNgplscaqn](?!.))*") %>%
    as.character()
}
