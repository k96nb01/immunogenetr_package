#' @title HLA_mismatch_number_HvG
#'
#' @description A function that counts the number of alleles in the donor that are not present in the recipient for a specified locus.
#'
#' @param GL_string_recip GL string for the HLA data of the recipient.
#' @param GL_string_donor GL string for the HLA data of the donor.
#' @param locus The name of the locus for which the function checks for a mismatch.
#'
#' @return An integer indicating the number of mismatched alleles.
#'
#' @examples
#' GL_string_recip <- "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQA1*02:01+HLA-DQA1*03:01^HLA-DQB1*02:02+HLA-DQB1*03:02^HLA-DPA1*01:03+HLA-DPA1*02:01^HLA-DPB1*01:01+HLA-DPB1*16:01"
#' GL_string_donor <- "HLA-A*03:01+HLA-A*30:01^HLA-C*07:02+HLA-C*12:03^HLA-B*07:02+HLA-B*38:01^HLA-DRB3*01:01^HLA-DRB5*01:01^HLA-DRB1*03:01+HLA-DRB1*15:01^HLA-DQA1*01:02+HLA-DQA1*05:01^HLA-DQB1*02:01+HLA-DQB1*06:02^HLA-DPA1*01:03+HLA-DPA1*01:03^HLA-DPB1*04:01+HLA-DPB1*04:01"
#' locus <- "HLA-B"
#' result <- HLA_mismatch_HvG(GL_string_recip, GL_string_donor, locus)
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stats na.omit

HLA_mismatch_number_HvG <- function(GL_string_recip, GL_string_donor, loci, homozygous_count = 1) {
  # Check for ambiguity
  if (str_detect(GL_string_recip, "[|/]") | str_detect(GL_string_donor, "[|/]")) {
    stop("HLA_mismatch_number_HvG does not support ambiguous GL strings that contain the delimiters | or /")
  }

  # Normalize loci input
  loci <- gsub("HLA_", "", loci)  # Remove HLA_ if present
  loci <- gsub("HLA-", "", loci)  # Remove HLA- if present

  # Process recipient and donor GL strings
  recip_data <- GLstring_expand_longer(GL_string_recip)
  donor_data <- GLstring_expand_longer(GL_string_donor)

  # Initialize list to store mismatch counts
  mismatch_counts <- list()

  # Check mismatch for each locus
  for (locus in loci) {
    full_locus <- paste0("HLA-", locus)

    # Check if the specified locus exists in both datasets
    if (!(full_locus %in% recip_data$locus) | !(full_locus %in% donor_data$locus)) {
      stop(paste("Locus", full_locus, "not found in both recipient and donor data."))
    }

    # Filter data for specified locus
    recip_locus_data <- recip_data %>% filter(locus == full_locus)
    donor_locus_data <- donor_data %>% filter(locus == full_locus)

    # Extract unique alleles for specified locus
    recip_alleles <- unique(recip_locus_data$value)
    donor_alleles <- donor_locus_data$value

    # Check homozygous_count
    if (homozygous_count == 1) {
      donor_alleles <- unique(donor_alleles)
    }

    # Identify mismatched alleles
    mismatches <- donor_alleles[!donor_alleles %in% recip_alleles]

    # If homozygous_count is 2, count duplicates in mismatches
    if (homozygous_count == 2) {
      mismatch_counts[[locus]] <- sum(table(mismatches))
    } else {
      mismatch_counts[[locus]] <- length(mismatches)
    }
  }

  # Return result
  if (length(loci) == 1) {
    return(mismatch_counts[[loci]])
  } else {
    return(paste(sapply(names(mismatch_counts), function(locus) {
      paste0(locus, ":", mismatch_counts[[locus]])
    }), collapse = ","))
  }
}
