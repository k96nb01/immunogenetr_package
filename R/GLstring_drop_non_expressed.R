#' @title GLstring_drop_non_expressed
#'
#' @description This function removes alleles carrying a WHO expression suffix
#' from a GL String. By default the suffixes N (null), S (secreted) and C
#' (cytoplasmic) are removed, on the reasoning that these alleles do not produce
#' a protein at the cell surface; L (low), Q (questionable) and A (aberrant)
#' alleles are kept, as some surface expression is possible. Which suffixes to
#' treat as non-expressed is a clinical judgement, so the `suffixes` argument
#' can be set to any combination of the six.
#'
#' Removal operates on whole alleles at any level of the GL String hierarchy:
#' an allele ambiguity list narrows, a gene copy with no expressed alleles
#' collapses, and a locus with no expressed alleles disappears along with its
#' delimiter. If nothing in a GL String survives, `NA` is returned for that
#' entry.
#'
#' @param GL_string A character vector of GL Strings.
#' @param suffixes A character vector of WHO expression suffixes to remove.
#' Any combination of "N", "Q", "L", "S", "C" and "A". Defaults to
#' `c("N", "S", "C")`.
#'
#' @return A character vector of GL Strings with the selected alleles removed,
#' the same length as `GL_string`. Entries with no remaining alleles are `NA`.
#'
#' @examples
#' # A null allele is removed from an allele ambiguity list, and a gene copy
#' # with no expressed alleles collapses:
#' GLstring_drop_non_expressed(
#'   "HLA-A*01:01N+HLA-A*02:01^HLA-B*07:02/HLA-B*07:02N+HLA-B*08:01"
#' )
#'
#' # A locus with no expressed alleles disappears along with its delimiter:
#' GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*02:01N^HLA-B*07:02+HLA-B*08:01")
#'
#' # L, Q and A alleles are kept by default; narrow `suffixes` to remove only
#' # null alleles:
#' GLstring_drop_non_expressed("HLA-A*24:02Q+HLA-A*01:01")
#' GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*30:14L", suffixes = "N")
#'
#' @export
#'
#' @importFrom cli cli_abort
#' @importFrom stringr str_c
#' @importFrom stringr str_detect
#' @importFrom stringr str_flatten

GLstring_drop_non_expressed <- function(GL_string, suffixes = c("N", "S", "C")) {
  # Validate input
  check_gl_string(GL_string, "GL_string")

  # G and P are deliberately not accepted: they name allele groups, not expression variants.
  valid_suffixes <- c("N", "Q", "L", "S", "C", "A")
  if (!is.character(suffixes) || length(suffixes) == 0 || anyNA(suffixes) || any(!suffixes %in% valid_suffixes)) {
    cli_abort("{.arg suffixes} must be one or more of {.val {valid_suffixes}}.")
  }

  # NA entries pass through as NA; entries whose alleles are all removed end up NA as well.
  out <- rep(NA_character_, length(GL_string))
  todo <- which(!is.na(GL_string))
  if (length(todo) == 0) {
    return(out)
  }

  # Expand to the ambiguity table, drop every allele ending in one of the selected suffixes, and reassemble. The table's `entry` column indexes into the expanded input, and `ambiguity_table_to_GLstring` returns one GL String per surviving entry in ascending entry order, so results map back by position.
  table <- GLstring_expand_longer(GL_string[todo])
  suffix_regex <- str_c("[", str_flatten(suffixes), "]$")
  kept <- table[!str_detect(table$value, suffix_regex), ]
  if (nrow(kept) > 0) {
    out[todo[unique(kept$entry)]] <- ambiguity_table_to_GLstring(kept)
  }
  out
}
