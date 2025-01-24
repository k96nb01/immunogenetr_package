#' @title HLA_match_number_GvH
#'
#' @description Calculates the number of HLA matches in the GvH direction as two
#' minus the number of mismatches from `HLA_mismatch_number`. Homozygous mismatches
#' are counted twice.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
#'
#' @return An integer value or a character string:
#' - If `loci` includes only one locus, the function returns an integer
#' mismatch count for that locus.
#' - If `loci` includes multiple loci, the function returns a character
#' string in the format "Locus1=Count1, Locus2=Count2, ...".
#'
#' @examples
#' # Example recipient and donor GL strings
#' GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
#' GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02"
#' loci <- c("HLA-A", "HLA-B")
#'
#' # Calculate mismatch numbers
#' HLA_match_number(GL_string_recip, GL_string_donor, loci)
#'
#' @export
#'

HLA_match_number_GvH <- function(GL_string_recip, GL_string_donor, loci){
  HLA_match_number(GL_string_recip, GL_string_donor, loci, "GvH")
}


