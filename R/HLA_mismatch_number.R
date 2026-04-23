#' @title HLA_mismatch_number
#'
#' @description Calculates the number of mismatched HLA alleles between a
#' recipient and a donor across specified loci. Supports mismatch calculations
#' for host-vs-graft (HvG), graft-vs-host (GvH), or bidirectional.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (the max value of "HvG" and "GvH"), or "SOT" (host vs. graft, as is used for
#' mismatching in solid organ transplantation).
#' @param homozygous_count An integer specifying how to count homozygous mismatches.
#' Defaults to 2, where homozygous mismatches are treated as two mismatches,
#' regardless if one or two alleles are supplied in the GL string (in cases
#' where one allele is supplied, it is duplicated by the function). If
#' specified as 1, homozygous mismatches are only counted once, regardless of
#' whether one or two alleles are supplied in the GL string (in cases where
#' two alleles are supplied, the second identical allele is deleted).
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
#'
#' GL_string_recip <- GL_string[1]
#' GL_string_donor <- GL_string[2]
#'
#' loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
#'
#' # Calculate mismatch numbers (Host vs. Graft)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#'
#' # Calculate mismatch numbers (Graft vs. Host)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#'
#' # Calculate mismatch numbers (Bidirectional)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor,
#'   loci,
#'   direction = "bidirectional"
#' )
#'
#' @export


HLA_mismatch_number <- function(GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2) {
  # Validate inputs at the user-facing layer. The internal matrix helper
  # (`hla_mismatch_count_matrix`) intentionally skips these checks so it can
  # be called hot from HLA_match_number / HLA_match_summary_HCT without the
  # same GL strings being re-validated on every invocation.
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)
  check_homozygous_count(homozygous_count)

  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional", "SOT"))

  # Build the per-locus per-pair integer mismatch count matrix. Shape is
  # (n_loci, n_pairs) in both single-locus and multi-locus cases.
  cnt <- hla_mismatch_count_matrix(
    GL_string_recip, GL_string_donor, loci, direction, homozygous_count
  )

  n_loci <- length(loci)

  # Single-locus: flatten the 1-row matrix to an integer vector. This matches
  # the historical return type (integer vector of length n_pairs).
  if (n_loci == 1L) {
    return(as.integer(cnt[1L, ]))
  }

  # Multi-locus: format each column as "LOCUS=Count, LOCUS=Count, ...". If any
  # locus is NA for a pair (e.g. pair's mismatch_base returned NA_character_),
  # the whole pair's string becomes NA_character_ to preserve the existing
  # contract.
  n_pairs <- ncol(cnt)
  out <- character(n_pairs)
  for (j in seq_len(n_pairs)) {
    col <- cnt[, j]
    if (anyNA(col)) {
      out[j] <- NA_character_
    } else {
      out[j] <- paste0(loci, "=", col, collapse = ", ")
    }
  }
  out
}


# --- Internal helper ------------------------------------------------------
#
# Returns an integer matrix of shape (n_loci, n_pairs) of the per-locus
# per-pair mismatch count. Column j is NA-filled when HLA_mismatch_base
# returned NA_character_ for that pair. Direction semantics match the
# user-facing HLA_mismatch_number: "HvG"/"SOT" use one call to the base,
# "GvH" another, and "bidirectional" takes the element-wise max of the two.
#
# Inputs are assumed already validated — this helper is called from multiple
# user-facing wrappers (HLA_mismatch_number, HLA_match_number,
# HLA_match_summary_HCT) and does not re-run check_gl_string / check_loci /
# check_homozygous_count. Direction is assumed to be one of the four allowed
# strings (match.arg has already run).
#
# Rationale: the former in-place `count_matrix` closure inside
# HLA_mismatch_number was duplicated in spirit by HLA_match_number (which
# parsed the formatted "LOCUS=N, ..." string back to integers) and by
# HLA_match_summary_HCT (which parsed it *again* to sum). Exposing the
# matrix once lets the match wrappers consume it directly without any
# string round-trip.

hla_mismatch_count_matrix <- function(GL_string_recip, GL_string_donor, loci,
                                      direction, homozygous_count = 2) {
  n_loci <- length(loci)

  # Pre-decide which directional base calls we need. "SOT" is a HvG alias
  # (solid-organ transplantation uses the same calculation).
  need_HvG <- direction %in% c("HvG", "SOT", "bidirectional")
  need_GvH <- direction %in% c("GvH", "bidirectional")

  # Count mismatched alleles in a single "VALUE" token from the base output.
  # Base joins mismatches with "+", so the count is (# of "+") + 1 unless the
  # token is the literal "NA" (meaning no mismatch at this locus for this
  # pair). The `charToRaw` + as.raw(0x2B) trick counts the "+" byte directly
  # in bytes without calling the regex engine; this was iteration 3's win
  # and is preserved here.
  count_val <- function(v) {
    if (is.na(v) || v == "NA") return(0L)
    sum(charToRaw(v) == as.raw(0x2B)) + 1L
  }

  # Build the integer matrix from a character vector of base-output strings.
  # Single-locus and multi-locus are handled with a single code path — the
  # single-locus base output is already the raw "VALUE" token per pair (no
  # "LOCUS=" prefix and no ", " separator), so we branch once up top.
  count_matrix <- function(raw) {
    n <- length(raw)
    out <- matrix(NA_integer_, nrow = n_loci, ncol = n)
    if (n_loci == 1L) {
      # Single-locus fast path: each element of `raw` is the VALUE token.
      for (j in seq_len(n)) out[1L, j] <- count_val(raw[[j]])
    } else {
      # Multi-locus: split on ", " to get per-locus tokens, split each token
      # at "=" with regexpr + substr (faster than a regex-based sub), count.
      for (j in seq_len(n)) {
        rj <- raw[[j]]
        if (is.na(rj)) next
        parts <- strsplit(rj, ", ", fixed = TRUE)[[1L]]
        eq_pos <- regexpr("=", parts, fixed = TRUE)
        vals <- substr(parts, eq_pos + 1L, nchar(parts))
        k <- min(length(vals), n_loci)
        for (i in seq_len(k)) out[i, j] <- count_val(vals[[i]])
      }
    }
    out
  }

  if (need_HvG) {
    mat_HvG <- count_matrix(
      HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count)
    )
  }
  if (need_GvH) {
    mat_GvH <- count_matrix(
      HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count)
    )
  }

  # pmax on two matrices of identical shape preserves the matrix dim (tested
  # locally against R 4.5.3). na.rm = TRUE mirrors the historical behavior
  # of HLA_mismatch_number, where a single-side NA still contributes the
  # non-NA side to the bidirectional count.
  switch(direction,
    HvG           = mat_HvG,
    SOT           = mat_HvG,
    GvH           = mat_GvH,
    bidirectional = pmax(mat_HvG, mat_GvH, na.rm = TRUE)
  )
}
