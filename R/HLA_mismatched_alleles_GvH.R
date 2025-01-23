#' @title HLA_mismatched_alleles_GvH
#'
#' @description A wrapper for the `HLA_mismatched_alleles` function: returns a string
#' of mismatches between recipient and donor HLA genotypes in the graft-versus-host
#' direction.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
#' @param homozygous_count An integer specifying how to handle homozygosity.
#' Defaults to 2, where homozygous alleles are treated as duplicated for
#' mismatch calculations. Can be specified as 1, in which case homozygous
#' alleles are treated as single occurrences without duplication (in other words,
#' homozyougs mismatches are only "counted" once).
#'
#' @return A character vector, where each element is a string summarizing the
#' mismatches for the specified loci. The strings are formatted as
#' comma-separated locus mismatch entries if multiple loci were supplied, or as
#' simple GL strings if a single locus was supplied.

#'
#' @examples
#' GL_string_recip <- "HLA-A2+HLA-A68^HLA-Cw1+HLA-Cw17^HLA-DR1+HLA-DR17^HLA-DR52
#' ^HLA-DPB1*04:01"
#' GL_string_donor <- "HLA-A3+HLA-A69^HLA-Cw10+HLA-Cw9^HLA-DR4+HLA-DR17^HLA-DR52
#' +HLA-DR53^HLA-DPB1*04:01+HLA-DPB1*04:02"
#' loci <- c("HLA-A", "HLA-Cw", "HLA-DR51/52/53", "HLA-DPB1")
#' HLA_mismatched_alleles_GvH(GL_string_recip, GL_string_donor, loci)
#'
#'
#' @export
#'
#' @importFrom stringr str_c
#' @importFrom tibble tibble
#' @importFrom magrittr  %>%
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom tidyr replace_na
#' @importFrom stringr str_c
#' @importFrom tidyr unite

HLA_mismatched_alleles_GvH <- function(GL_string_recip, GL_string_donor, loci, homozygous_count = 2) {
  HLA_mismatched_alleles(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count)
}
