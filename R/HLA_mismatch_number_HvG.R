#' @title HLA_mismatch_number_HvG
#'
#' @description A wrapper for `HLA_mismatch_number`: calculates the number of
#' mismatched HLA alleles between a recipient and a donor across specified loci
#' in the HvG (Host vs. Graft) direction.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
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
#' # Example recipient and donor GL strings
#' GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
#' GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02"
#' loci <- c("HLA-A", "HLA-B")
#'
#' # Calculate mismatch numbers in the HvG direction
#' HLA_mismatch_number_HvG(GL_string_recip, GL_string_donor, loci)
#'
#' @export
#'

HLA_mismatch_number_HvG <- function(GL_string_recip, GL_string_donor, loci, homozygous_count = 2){
  # Call the original HLA_mismatch_number function with "HvG" direction
  return(HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count))
}
