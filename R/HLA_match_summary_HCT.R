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
#' @importFrom purrr map_int
#' @importFrom stringr str_extract_all
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

  # When scope is "genotype" and direction is "bidirectional",
  # calculate GvH and HvG match summaries separately, then take the maximum.
  # Each recursive call is already vectorized via map_int() below.
  if (scope == "genotype" && direction == "bidirectional") {
    # Calculate GvH match summary across all loci
    gvh_result <- HLA_match_summary_HCT(
      GL_string_recip, GL_string_donor,
      direction = "GvH", match_grade = match_grade, scope = "locus"
    )
    # Calculate HvG match summary across all loci
    hvg_result <- HLA_match_summary_HCT(
      GL_string_recip, GL_string_donor,
      direction = "HvG", match_grade = match_grade, scope = "locus"
    )
    # Return the maximum of the two directional totals (vectorized via pmax)
    return(pmax(gvh_result, hvg_result))
  }

  # Calculate match numbers across loci (returns "HLA-A=2, HLA-B=1, ..." per pair)
  match_strings <- HLA_match_number(
    GL_string_recip, GL_string_donor, loci, direction = direction
  )

  # Extract the numeric match counts from each string and sum them
  map_int(str_extract_all(match_strings, "(?<=\\=)\\d+"), ~ sum(as.integer(.x)))
}
