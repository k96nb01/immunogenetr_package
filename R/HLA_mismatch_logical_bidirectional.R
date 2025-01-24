#' @title HLA_mismatch_logical_bidirectional
#'
#' @description A wrapper for  `HLA_mismatch_logical`: determines if there are
#' any mismatches between recipient and donor in either direction.
#' Returns `TRUE` if mismatches are present, and `FALSE` otherwise.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
#'
#' @return A logical value (`TRUE` or `FALSE`):
#' - `TRUE` if there are mismatches between recipient and donor HLA alleles.
#' - `FALSE` if there are no mismatches.
#'
#' @examples
#' # Example recipient and donor GL strings
#' GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
#' GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-DRB3*03:01"
#'
#' # Check if there are mismatches for HLA-A (Graft vs. Host)
#' HLA_mismatch_logical_bidirectional(GL_string_recip, GL_string_donor, loci =
#' "HLA-A")
#'
#' @export
#'

HLA_mismatch_logical_bidirectional <- function(GL_string_recip, GL_string_donor, loci) {
  HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, "bidirectional")
}
