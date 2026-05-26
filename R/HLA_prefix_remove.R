#' @title HLA_prefix_remove
#'
#' @description This function removes HLA and optionally locus prefixes from a string of HLA typing:
#' "HLA-A2" changes to "A2" or "2". By default, HLA and locus prefixes are removed. This function
#' also works on each allele in a GL string.
#'
#' @param data A string with a single HLA allele, a GL string of HLA alleles,
#' or a character vector containing either of the previous.
#' @param keep_locus A logical value indicating whether to retain any locus values.
#' The default value is FALSE.
#'
#' @return A vector modified to remove HLA and optionally locus prefixes.
#'
#' @examples
#' # The HLA_typing_1 dataset contains a table with HLA typing spread across multiple columns:
#' print(HLA_typing_1)
#'
#' # The `HLA_prefix_remove` function can be used to get each column to have only the
#' # colon-separated fields:
#' library(dplyr)
#' HLA_typing_1 %>% mutate(
#'   across(
#'     A1:DPB1_2,
#'     ~ HLA_prefix_remove(.)
#'   )
#' )
#'
#' @export

HLA_prefix_remove <- function(data, keep_locus = FALSE) {
  # Validate inputs exactly as before so caller-visible error messages are preserved.
  check_gl_string(data, "data")
  check_logical_flag(keep_locus, "keep_locus")

  # -------------------------------------------------------------------------
  # Iteration 6 rewrite: operate on the GL string directly with regex
  # substitutions instead of the previous expand->mutate->reassemble pipeline.
  #
  # The old version called GLstring_expand_longer() (a 7-deep
  # separate_longer_delim chain) and ambiguity_table_to_GLstring() (six
  # summarise/str_flatten passes) just to strip a literal "HLA-" prefix and
  # a leading locus from each allele. Profiling showed this was the single
  # biggest cost in HLA_columns_to_GLstring on realistic inputs.
  #
  # The GL string operators ^, |, +, ~, /, ? each separate allele tokens.
  # None of them can appear inside an allele name, so matching "a prefix
  # at an allele boundary" is equivalent to matching "start of string
  # OR immediately after a GL operator" — which is what the gsub() passes
  # below encode.
  # -------------------------------------------------------------------------

  # Pass 1 — remove every "HLA-" species prefix.
  # fixed = TRUE skips the regex engine entirely since the pattern is
  # literal. Vectorised over `data`; NA entries pass through untouched.
  result <- gsub("HLA-", "", data, fixed = TRUE)

  if (!keep_locus) {
    # Pass 2a — strip the leading alphabetic locus prefix from the first
    # allele in the GL string. sub() is single-match so only the head is
    # touched. "[[:alpha:]]+" handles both single-letter loci (A, B, C)
    # and multi-letter ones (DRB1, DQA1, Cw, Bw).
    result <- sub("^[[:alpha:]]+", "", result)
    # Pass 2b — strip the same alphabetic locus prefix from every other
    # allele in the GL string. The allele boundary is any GL operator; we
    # capture it in group 1 and restore it via "\\1" so the operator is
    # retained. "\\^" inside the character class is a literal caret (not a
    # negation marker, because it is not the first character of the class).
    result <- gsub("([\\^|+~/?])[[:alpha:]]+", "\\1", result)
    # Pass 3a — strip a residual "digits*" locus prefix from the first
    # allele (e.g. "1*15:01" -> "15:01" for HLA-DRB1 after pass 2a). We use
    # sub() so only the first allele's prefix is consumed.
    result <- sub("^[[:digit:]]*\\*", "", result)
    # Pass 3b — strip the same "digits*" locus prefix from every other
    # allele in the GL string, using the GL-operator boundary pattern.
    result <- gsub("([\\^|+~/?])[[:digit:]]*\\*", "\\1", result)
  }

  result
}
