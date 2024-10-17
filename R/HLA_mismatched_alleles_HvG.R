#' @title HLA_mismatch_alleles_HvG
#'
#' @description A function that checks for alleles in the donor that are not present in the recipient
#' for a specified locus and returns a string of mismatched alleles. The function assumes two alleles
#' at each locus, even if homozygous results are entered as only one allele (e.g. "HLA-A*02:01" and
#' "HLA-A*02:01+HLA-A*02:01") are treated both assumed to indicate two identical alleles at the A locus.
#' If a mismatch from a homozygous locus is detected, two copies of that allele will be output (e.g.
#' "HLA-A*02:01+HLA-A*02:01"). This behavior can be overridden by setting homozygous_count = 1, so that
#' these homozygous alleles are only "counted" once. Null alleles (alleles ending in N or n) are not
#' counted at mismatches.
#'
#' @param GL_string_recip GL string for the HLA data of the recipient.
#' @param GL_string_donor GL string for the HLA data of the donor.
#' @param loci The name of the loci for which the function checks for a mismatch; multiple loci should be entered as vectors (e.g.
#' c("HLA-A", "HLA-DRB1")).
#' @param homozygous_count Whether to count homozygous mismatches as 1 or two alleles; 2 is the default.
#'
#' @return A string of mismatched alleles at each locus. If there are no mismatches, returns "NA".
#'
#' @examples
#' GL_string_recip <- "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQA1*02:01+HLA-DQA1*03:01^HLA-DQB1*02:02+HLA-DQB1*03:02^HLA-DPA1*01:03+HLA-DPA1*02:01^HLA-DPB1*01:01+HLA-DPB1*16:01"
#' GL_string_donor <- "HLA-A*03:01+HLA-A*30:01^HLA-C*07:02+HLA-C*12:03^HLA-B*07:02+HLA-B*38:01^HLA-DRB3*01:01^HLA-DRB5*01:01^HLA-DRB1*03:01+HLA-DRB1*15:01^HLA-DQA1*01:02+HLA-DQA1*05:01^HLA-DQB1*02:01+HLA-DQB1*06:02^HLA-DPA1*01:03+HLA-DPA1*01:03^HLA-DPB1*04:01+HLA-DPB1*04:01"
#' locus <- "A"
#' result <- HLA_mismatch_alleles_HvG(GL_string_recip, GL_string_donor, locus)
#' print(result)
#'
#' @export
#'
#' @importFrom stringr str_detect
#' @importFrom stringr str_replace_all
#' @importFrom dplyr %>%
#' @importFrom dplyr first
#' @importFrom purrr map
#' @importFrom purrr map2



HLA_mismatched_alleles_HvG <- function(GL_string_recip, GL_string_donor, loci, homozygous_count = 2) {
  # Check for ambiguity
  if (str_detect(GL_string_recip, "[|/]") | str_detect(GL_string_donor, "[|/]")) {
    stop("HLA_mismatch_HvG does not support ambiguous GL strings with | or /")
  }

  # Split GL strings by "^" to separate different loci
  recip_alleles_list <- unlist(strsplit(GL_string_recip, "\\^"))
  donor_alleles_list <- unlist(strsplit(GL_string_donor, "\\^"))

  # Normalize loci names by removing "HLA-" prefix and any "*" characters
  normalized_loci <- gsub("HLA-", "", loci)

  # Extract unique locus names present in recipient and donor data without asterisks (*)
  available_loci_recip <- unique(gsub("\\*.*", "", recip_alleles_list)) %>% str_replace_all(., "HLA[_-]?", "")
  available_loci_donor <- unique(gsub("\\*.*", "", donor_alleles_list)) %>% str_replace_all(., "HLA[_-]?", "")

  # Check if all specified loci exist in both recipient and donor data
  missing_loci_names <- setdiff(normalized_loci, intersect(available_loci_recip, available_loci_donor))

  if (length(missing_loci_names) > 0) {
    stop(paste("Loci not found in both recipient and donor data:", paste(missing_loci_names, collapse = ", ")))
  }

  # Iterate over each locus and corresponding allele strings from recipient and donor
  mismatch_results <- map2(normalized_loci, seq_along(normalized_loci), ~{
    locus_name <- .x
    locus_index <- .y

    # Pull out the allele list for each locus.
    recip_alleles_str <- recip_alleles_list[locus_index]
    donor_alleles_str <- donor_alleles_list[locus_index]

    # Check for homozygosity.
    recip_homozygous <- (length(unique(str_split(recip_alleles_str,"\\+")[[1]])) == 1)
    donor_homozygous <- (length(unique(str_split(donor_alleles_str,"\\+")[[1]])) == 1)

    # Split the recipient and donor alleles and remove elements ending with 'n' or 'N'.
    recip_alleles_split<-first(str_split(recip_alleles_str,"\\+") %>%
                                 map(discard, ~str_detect(., "[nN]$")))
    donor_alleles_split<-first(str_split(donor_alleles_str,"\\+") %>%
                                 map(discard, ~str_detect(., "[nN]$")))

    # Find mismatched HvG alleles: present in the donor but not in the recipient
    mismatched_alleles <- setdiff(donor_alleles_split, recip_alleles_split)

    # Duplicate the mismatch if it is homozygous
    if (length(unique(mismatched_alleles)) == 1 && donor_homozygous) {
      mismatched_alleles <- rep(mismatched_alleles, homozygous_count)
    }

    # Create a string of mismatched alleles or 'NA' if no mismatches are found.
    allele_mismatches_str <-
      if (length(mismatched_alleles) > 0) {
        paste0(locus_name, ":", paste(mismatched_alleles, collapse = "+"))
      } else {
        paste0(locus_name, ":NA")
      }

    return(allele_mismatches_str)
  })

  # Paste all loci back together.
  paste(mismatch_results, collapse = ",")
}
