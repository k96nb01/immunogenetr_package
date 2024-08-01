#' @title HLA_truncate
#'
#' @description This function truncates the HLA typing values. The truncation
#' is based on the number of fields specified and optionally retains any
#' WHO-recognized suffixes (L, S, C, A, Q, or N). Note this will not keep
#' G or P group designations, as these are defined to specific fields
#' (3 fields for G groups, and 2 fields for P groups), so if typings
#' are to be truncated, the G or P group nomenclature is not being preserved.
#'
#' @param data A string containing an HLA type.
#' @param fields An integer specifying the number of fields to retain in the
#' truncated values. Default is 2.
#' @param keep_suffix A logical value indicating whether to retain any
#' WHO-recognized suffixes. Default is TRUE.
#'
#' @return A string with the HLA typing truncated according to
#' the specified number of fields and optional suffix retention.
#'
#' @examples
#' typing <- "A*01:01:01:02N"
#' HLA_truncate(typing, fields = 2, keep_suffix = FALSE) # "A*01:01"
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

HLA_truncate <- function(data, fields = 2, keep_suffix = TRUE) {
  # Split the input GL string into individual alleles
  alleles <- strsplit(data, "\\^")[[1]]

  # Initialize an empty vector to store truncated alleles
  truncated_alleles <- vector("character", length(alleles))

  # Loop through each allele to apply truncation
  for (i in seq_along(alleles)) {
    allele <- alleles[i]

    # Extract fields based on the number of fields specified
    A <- if (fields == 3) {
      str_extract(allele, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}:?[:digit:]{0,4}")
    } else if (fields == 2) {
      str_extract(allele, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}")
    } else if (fields == 1) {
      str_extract(allele, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}")
    } else {
      str_extract(allele, "(HLA-)?([:alnum:]{0,4})(\\*)?[:digit:]{1,4}:?[:digit:]{0,4}:?[:digit:]{0,4}:?[:digit:]{0,4}")
    }

    # Extract any WHO-recognized suffixes
    B <- replace_na(str_extract(allele, "[LSCAQNlscaqn]$"), "")

    # Glue truncated typing and suffixes if indicated
    if (keep_suffix == TRUE) {
      truncated_alleles[i] <- na_if(str_c({A}, {B}, sep = ""), "NA")
    } else {
      truncated_alleles[i] <- A
    }
  }

  # Join the truncated alleles back into a single string
  truncated_string <- paste(truncated_alleles, collapse = "^")

  return(truncated_string)
}
