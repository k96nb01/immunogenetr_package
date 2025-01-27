#' @title GLstring_regex
#'
#' @description This function will format an HLA allele (e.g. "HLA-A*02:01") to
#' a regex pattern for searching within a GL string. Note that in order for this
#' function to work properly, the full HLA allele name, including prefixes, is
#' required. Allele values of "A*02:01" will need to be updated to "HLA-A*02:01",
#' and "A2" will need to be updated to "HLA-A2". The `HLA_prefix_add` function
#' is useful in these situations.
#'
#' @param data A string containing an HLA allele.
#'
#' @return A string with the HLA allele formatted as a regex pattern.
#'
#' @examples
#' allele <- "HLA-A*02:01"
#' GLstring_regex(allele)
#'
#' @export
#'
#' @importFrom stringr str_detect
#' @importFrom stringr str_c
#' @importFrom stringr str_escape
#' @importFrom tibble tibble
#' @importFrom dplyr mutate

GLstring_regex <- function(data) {
  # This regex will only work if the full HLA allele, including the "HLA-" prefix is present. This will throw an error if "HLA-" is not detected in the allele to be modified.
  if (any(!str_detect(data, "HLA-"))) {
    stop(print('In order for the regex expression to work properly, all alleles must have the full HLA- prefix. Process your data to add the full HLA allele name before passing the results to `GLstring_regex`.'))
  }
  # Format the HLA alleles for searching within a GL string.
  table <- tibble(alleles = data) %>%
    mutate(alleles_regex = str_c(str_escape(alleles), "(?=(\\?|\\^|\\||\\+|\\~|/|$))")) # The regex includes all the delimiters in a GL string and the end of a string.
  return(table$alleles_regex)
}
