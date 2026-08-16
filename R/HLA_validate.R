#' @title HLA_validate
#'
#' @description Returns only HLA alleles in valid nomenclature, either serologic or molecular.
#' Simple numbers, such as "2" or "27" will be returned as-is. Suffixes that are not
#' WHO-recognized suffixes (L, S, C, A, Q, N) or G or P group designations will be removed.
#' For example "novel" at the end of the allele will be removed, while "n" at the end of the
#' allele will be retained. Other values, such as "blank" or "-" will be converted to NA values.
#' This function is helpful for cleaning up the typing of an entire table of HLA values.
#'
#' Each value is expected to hold a single allele. If a value contains GL String
#' delimiters ("^", "|", "+", "~", "/" or "?"), only the first allele is retained
#' (the historical behavior, controlled by `take_first_allele`); set
#' `take_first_allele = FALSE` to treat such values as malformed input and get
#' an error instead. Use the GL String functions (e.g. `GLstring_expand_longer`)
#' to work with multi-allele values.
#'
#'
#' @param data A string containing an HLA allele.
#' @param take_first_allele A logical value. If TRUE (the default), a value
#' containing GL String delimiters is silently reduced to its first allele.
#' If FALSE, such values raise an error instead, for callers that want
#' malformed multi-allele input caught rather than truncated.
#'
#' @return A string with a valid HLA allele or NA if no valid allele was present.
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
#' # The HLA_typing_LIS dataset contains a table with HLA typing spread across multiple columns:
#' print(HLA_typing_LIS)
#'
#' # Cleaning up the entire table. Note that blank values will be converted to "NA".
#' library(dplyr)
#' HLA_typing_LIS %>% mutate(
#'   across(
#'     mA1Cd.recipient:mDPB12cd.recipient,
#'     ~ HLA_validate(.)
#'   )
#' )
#' @export
#'
#' @importFrom cli cli_abort
#' @importFrom dplyr %>%
#' @importFrom stringr str_detect
#' @importFrom stringr str_extract

HLA_validate <- function(data, take_first_allele = TRUE) {
  check_logical_flag(take_first_allele, "take_first_allele")

  # The function cleans one allele per value: str_extract below keeps only the
  # first allele of a multi-allele value. take_first_allele = TRUE preserves
  # that historical behavior; FALSE turns it into an error for callers that
  # want malformed input caught rather than truncated.
  if (!take_first_allele) {
    gl_input <- !is.na(data) & str_detect(as.character(data), "[\\^\\|\\+\\~/\\?]")
    if (any(gl_input)) {
      cli_abort("{sum(gl_input)} value{?s} passed to {.fn HLA_validate} contain{?s/} GL String delimiters (e.g. {.val {as.character(data)[gl_input][1]}}), but each value must hold a single allele when {.arg take_first_allele} is FALSE. Use the GL String functions (e.g. {.fn GLstring_expand_longer}) to work with multi-allele values.")
    }
  }

  data %>%
    str_extract("(HLA-)?([:alnum:]*)(\\*)?[:digit:]{1,}:?[:digit:]*:?[:digit:]*:?[:digit:]*([GPLSCAQNgplscaqn](?!.))*") %>%
    as.character()
}
