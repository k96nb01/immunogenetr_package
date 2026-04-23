#' @title HLA_match_summary_HCT
#'
#' @description Calculates the match summary for either the HLA-A, B, C and DRB1
#' loci (out-of-8 matching) or the HLA-A, B, C, DRB1 and DQB1 loci (out-of-10 matching),
#' as is commonly used for hematopoietic cell transplantation (HCT). Homozygous
#' mismatches are counted twice. Bidirectional matching is the default, but can
#' be overridden with the "direction" argument.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype,
#' and minimally containing the HLA-A, B, C and DRB1 loci (for Xof8 matching)
#' or the HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).
#' @param GL_string_donor A GL string representing the donor's HLA genotype,
#' and minimally containing the HLA-A, B, C and DRB1 loci (for Xof8 matching)
#' or the HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).
#' @param direction "GvH", "HvG" or "bidirectional". Default is "bidirectional".
#' @param match_grade "Xof8" for HLA-A, B, C and DRB1 matching or "Xof10" for
#' HLA-A, B, C, DRB1 and DQB1 matching.
#' @param scope "locus" or "genotype". Default is "locus". When "locus" (the default),
#' bidirectional matching takes the minimum match count at each locus independently
#' before summing. When "genotype", the GvH and HvG match summaries are calculated
#' separately across all loci, and the maximum of the two totals is returned.
#' Only affects results when direction is "bidirectional"; ignored otherwise.
#'
#' @return An integer value of the match grade summary.
#'
#' @examples
#' # Example recipient and donor GL strings
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#'
#' GL_string_recip <- GL_string[1]
#' GL_string_donor <- GL_string[2]
#'
#' # Calculate mismatch numbers
#' HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
#'   direction = "bidirectional", match_grade = "Xof8"
#' )
#'
#' # Genotype-level bidirectional matching (max of GvH and HvG totals)
#' HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
#'   direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
#' )
#'
#' @export
#'

HLA_match_summary_HCT <- function(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade, scope = "locus") {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  match_grade <- match.arg(match_grade, c("Xof8", "Xof10"))
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))
  scope <- match.arg(scope, c("locus", "genotype"))

  # Determine loci based on match grade
  loci <- if (match_grade == "Xof8") {
    c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1")
  } else {
    c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1", "HLA-DQB1")
  }

  # Helper: turn a (n_loci, n_pairs) mismatch-count matrix into a length-N
  # integer vector of per-pair total matches. `2L - mm` gives the match
  # matrix; colSums gives the per-pair total. If any locus is NA for a pair,
  # colSums returns NA for that pair, which we then coerce to NA_integer_ so
  # the return type is always integer (preserving the baseline's
  # `map_int(...)` contract — tests use `expect_type(result, "integer")`).
  totals_from_mm <- function(mm) {
    match_mat <- 2L - mm
    totals <- colSums(match_mat)
    # colSums returns double; cast to integer. NA_real_ -> NA_integer_ cleanly.
    as.integer(totals)
  }

  # Genotype-scope bidirectional: compute GvH and HvG totals separately at
  # the genotype level, return the per-pair max. This replaces the previous
  # two recursive calls back through HLA_match_summary_HCT -> HLA_match_number
  # -> HLA_mismatch_number, each of which went through the tidyverse parse
  # pipeline. One matrix call per direction is enough.
  if (scope == "genotype" && direction == "bidirectional") {
    mm_HvG <- hla_mismatch_count_matrix(
      GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count = 2
    )
    mm_GvH <- hla_mismatch_count_matrix(
      GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count = 2
    )
    return(pmax(totals_from_mm(mm_HvG), totals_from_mm(mm_GvH)))
  }

  # Locus-scope, or non-bidirectional direction: a single matrix-helper call
  # handles everything. For direction == "bidirectional" the helper already
  # takes pmax(HvG, GvH) per cell; summing (2 - that) across loci is the
  # "minimum at each locus before summing" semantic the docstring promises.
  mm <- hla_mismatch_count_matrix(
    GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2
  )
  totals_from_mm(mm)
}
