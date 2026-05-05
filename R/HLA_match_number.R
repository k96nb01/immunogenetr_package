#' @title HLA_match_number
#'
#' @description Calculates the number of HLA matches as two minus the number of
#' mismatches from `HLA_mismatch_number`. Homozygous mismatches are counted twice.
#' Supports match calculations for host-vs-graft (HvG), graft-vs-host (GvH),
#' or bidirectional. Bidirectional matching is the default, but can be overridden
#' using the "direction" argument.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of match.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (the minimum value of "HvG" and "GvH").
#'
#' @return An integer value or a character string:
#' - If `loci` includes only one locus, the function returns an integer
#' mismatch count for that locus.
#' - If `loci` includes multiple loci, the function returns a character
#' string in the format "Locus1=Count1, Locus2=Count2, ...".
#'
#' @examples
#'
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#' GL_string_recip <- GL_string[1]
#' GL_string_donor <- GL_string[2]
#'
#' loci <- c("HLA-A", "HLA-B")
#'
#' # Calculate mismatch numbers (Host vs. Graft)
#' HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#'
#' # Calculate mismatch numbers (Graft vs. Host)
#' HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#'
#' # Calculate mismatch numbers (Bidirectional)
#' HLA_match_number(GL_string_recip, GL_string_donor,
#'   loci,
#'   direction = "bidirectional"
#' )
#'
#' @export
#'

HLA_match_number <- function(GL_string_recip, GL_string_donor, loci, direction = "bidirectional") {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)

  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))

  # Pull the per-locus per-pair mismatch count matrix directly from the
  # internal helper, skipping the round-trip through HLA_mismatch_number's
  # formatted string. Shape is (n_loci, n_pairs). homozygous_count is not
  # exposed at this function's API (see test-HLA_match_number.R:67-68),
  # so we always pass the default of 2.
  mm <- hla_mismatch_count_matrix(
    GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2
  )

  n_loci <- length(loci)

  # Single-locus: return the length-N match-count vector. The baseline used
  # `tibble(mismatch = ...) |> mutate(match = 2 - mismatch)`, which produced
  # a numeric (double) column because `2` is double. We preserve that type
  # here with `2 - as.integer(mm[1, ])` so identical() holds against the
  # pre-merge output.
  if (n_loci == 1L) {
    return(2 - as.integer(mm[1L, ]))
  }

  # Multi-locus: build "LOCUS=Matches, LOCUS=Matches, ..." per pair. If any
  # locus is NA for a pair (mismatch_base returned NA_character_), the whole
  # pair is NA_character_, matching the baseline's tidyverse pipeline which
  # let NA propagate through separate_wider_delim and unite.
  n_pairs <- ncol(mm)
  match_mat <- 2L - mm                         # (n_loci, n_pairs) integer
  out <- character(n_pairs)
  for (j in seq_len(n_pairs)) {
    col <- match_mat[, j]
    if (anyNA(col)) {
      out[j] <- NA_character_
    } else {
      out[j] <- paste0(loci, "=", col, collapse = ", ")
    }
  }
  out
}
