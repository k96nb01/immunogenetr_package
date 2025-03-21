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
#'
#' # To understand how the function works we can see how it alters the allele "HLA-A*02:01":
#'
#' GLstring_regex("HLA-A*02:01")
#'
#' # The result is the same allele with extra formatting to escape special characters found
#' # in a GL string, as well as the ability to accurately search for an allele in a GL string.
#' # For example, we would not want the allele "HLA-A*02:14" to match to "HLA-A*02:149:01",
#' # which would happen if we simply escaped the special characters:
#'
#' library(stringr)
#' str_view("HLA-A*02:149:01", str_escape("HLA-A*02:14"), match = NA)
#'
#' # Using `GLstring_regex` prevents this:
#'
#' str_view("HLA-A*02:149:01", GLstring_regex("HLA-A*02:14"), match = NA)
#'
#' # Using a longer GL string with multiple alleles and loci:
#'
#' GL_string <- "HLA-A*02:01:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01"
#'
#' # We can match any allele accurately:
#'
#' str_view(GL_string, GLstring_regex("HLA-A*68:01"), match = NA)
#'
#' # Note that alleles supplied with fewer fields than in the GL string will also match:
#'
#' str_view(GL_string, GLstring_regex("HLA-A*02:01"), match = NA)
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
    stop("In order for the regex expression to work properly, all alleles must have the full HLA- prefix. Process your data to add the full HLA allele name before passing the results to `GLstring_regex`.")
  }
  # Format the HLA alleles for searching within a GL string.
  table <- tibble(alleles = data) %>%
    mutate(alleles_regex = str_c(str_escape(alleles), "(?=(\\?|\\^|\\||\\+|\\~|/|:|$))")) # The regex includes all the delimiters in a GL string, a colon, which separates fields, and the end of a string.
  return(table$alleles_regex)
}
