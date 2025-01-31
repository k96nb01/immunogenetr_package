#' @title HLA_mismatched_alleles
#'
#' @description A function to return a string of mismatches between recipient
#' and donor HLA genotypes represented as GL strings. The function finds
#' mismatches based on the direction of comparison specified in the inputs
#' and also handles homozygosity.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (the max value of "HvG" and "GvH"), or "SOT" (host vs. graft, as is used for
#' mismatching in solid organ transplantation).
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
#' mismatches <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#' print(mismatches)
#'
#' # Output
#' # "HLA-A=HLA-A3+HLA-A69, HLA-Cw=HLA-Cw10+HLA-Cw9, HLA-DR51/52/53=HLA-DR53, HLA-DPB1=HLA-DPB1*04:02"

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

HLA_mismatched_alleles <- function(GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2) {
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional", "SOT"))
  # "HvG" or "GvH" can use the output of `HLA_mismatch_base` directly.
  if (direction == "HvG" | direction == "GvH") {
    HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction, homozygous_count)
    # "SOT" defaults to "HvG".
  } else if (direction == "SOT"){
    HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count)
    # "Bidirectional" will paste together the output of each direction.
  } else if (direction == "bidirectional") {
    HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count)
    GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count)
    # Combine the results from each direction
    bidirectional <- tibble("HvG" = HvG, "GvH" = GvH) %>%
      mutate(across(HvG:GvH, ~replace_na(., "NA"))) %>%
      mutate(HvG = str_c("HvG;", HvG), GvH = str_c("GvH;", GvH)) %>%
      unite(HvG, GvH, col = "bidirectional", sep = "<>")

    return(bidirectional$bidirectional)
  }
}
