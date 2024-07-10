#' @title HLA_truncate
#'
#' @description This function truncates the HLA typing values in the
#' identified columns of the given data frame. The truncation is based on
#' the number of fields specified and optionally retains any recognized
#' suffixes.
#'
#' @param data A data frame
#' @param columns Names of columns in the data to be truncated
#' @param fields An integer specifying the number of fields to retain in the
#' truncated values. Default is 2.
#' @param keep_suffix A logical value indicating whether to retain any
#' WHO-recognized suffixes. Default is TRUE.
#'
#' @return A data frame with the specified columns truncated according to
#' the specified number of fields and optional suffix retention.
#'
#' @examples
#' data(toydata)
#' output <- toydata %>% HLA_truncate(A.1, fields = 2, keep_suffix = TRUE)
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr %>%
#' @importFrom stringr str_extract
#' @importFrom stringr str_replace
#' @importFrom stringr str_c
#' @importFrom tidyr replace_na
#' @importFrom dplyr na_if

HLA_truncate <- function(data, columns, fields = 2, keep_suffix = TRUE) {
  # Extract first 3, 2, or 1 fields and any prefixes.
  if (fields == 3) {
    A <- str_extract(data, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}:?[:digit:]{0,4}")
  } else if (fields == 2) {
    A <- str_extract(data, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}")
  } else if (fields == 1) {
    A <- str_extract(data, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}")
  } else {
    A <- str_extract(data, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}:?[:digit:]{0,4}:?[:digit:]{0,4}")
  }

  {
    # Extract any WHO-recognized suffixes
    B <- replace_na(str_extract(data, "[LSCAQNlscaqn]$"), "")
  }

  {
    # Glue truncated typing and suffixes if indicated.
    if (keep_suffix == TRUE) {
      na_if(str_c({A}, {B}, sep = ""), "NA")
    } else {
      A
    }
  }
}
