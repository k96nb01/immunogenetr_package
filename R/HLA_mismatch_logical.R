#' @title HLA_mismatch_logical
#'
#' @description Determines if there are any mismatches between recipient and
#' donor HLA alleles for the specified loci. Returns `TRUE` if mismatches are
#' present, and `FALSE` otherwise.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (if either "HvG" or "GvH" is TRUE), or "SOT" (host vs. graft, as is used for
#' mismatching in solid organ transplantation).
#'
#' @return A logical value (`TRUE` or `FALSE`):
#' - `TRUE` if there are mismatches between recipient and donor HLA alleles.
#' - `FALSE` if there are no mismatches.
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
#' mismatches <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#' print(mismatches)
#'
#' @export
#'

HLA_mismatch_logical <- function(GL_string_recip, GL_string_donor, loci, direction) {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)

  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional", "SOT"))

  # Determine which direction(s) need to be computed.
  need_HvG <- direction %in% c("HvG", "SOT", "bidirectional")
  need_GvH <- direction %in% c("GvH", "bidirectional")

  # Single-locus path: HLA_mismatch_base returns NA for a perfect match, or
  # the mismatch value as a string. Presence of a mismatch == not NA.
  if (length(loci) == 1L) {
    if (need_HvG) HvG <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG"))
    if (need_GvH) GvH <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH"))
    return(switch(direction,
      HvG           = HvG,
      SOT           = HvG,
      GvH           = GvH,
      bidirectional = HvG | GvH
    ))
  }

  # Multi-locus path. HLA_mismatch_base returns a character vector where each
  # element is "LOCUS1=VAL1, LOCUS2=VAL2, ..." with "NA" meaning no mismatch
  # at that locus. We split each element once, compare the RHS to "NA" to get
  # a logical mismatch matrix (n_loci x N_pairs), and format each column back
  # into the user-facing "LOCUS=TRUE, LOCUS=FALSE" string.
  n_loci <- length(loci)

  mm_matrix <- function(raw) {
    n <- length(raw)
    out <- matrix(NA, nrow = n_loci, ncol = n)
    for (j in seq_len(n)) {
      rj <- raw[[j]]
      if (is.na(rj)) next
      parts <- strsplit(rj, ", ", fixed = TRUE)[[1L]]
      eq_pos <- regexpr("=", parts, fixed = TRUE)
      vals <- substr(parts, eq_pos + 1L, nchar(parts))
      k <- min(length(vals), n_loci)
      out[seq_len(k), j] <- vals[seq_len(k)] != "NA"
    }
    out
  }

  if (need_HvG) mm_HvG <- mm_matrix(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG"))
  if (need_GvH) mm_GvH <- mm_matrix(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH"))

  mm <- switch(direction,
    HvG           = mm_HvG,
    SOT           = mm_HvG,
    GvH           = mm_GvH,
    bidirectional = mm_HvG | mm_GvH
  )

  # Format each column into the "LOCUS=TRUE, LOCUS=FALSE" string.
  n_pairs <- ncol(mm)
  out <- character(n_pairs)
  for (j in seq_len(n_pairs)) {
    col <- mm[, j]
    if (anyNA(col)) {
      out[j] <- NA_character_
    } else {
      out[j] <- paste0(loci, "=", col, collapse = ", ")
    }
  }
  out
}
