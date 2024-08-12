#' @title HLA_mismatch_HvG
#'
#' @description A function that checks whether there are any alleles in the
#' donor that are not present in the recipient for a specified locus
#'
#' @param GL_string_recip GL string for the HLA data of the recipient
#' @param GL_string_donor GL string for the HLA data of the donor
#' @param locus The name of the locus for which the function checks for a
#' mismatch
#'
#' @return A boolean indicating whether there is a host vs. graft mismatch
#'
#' @example
#' GL_string_recip <- "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQA1*02:01+HLA-DQA1*03:01^HLA-DQB1*02:02+HLA-DQB1*03:02^HLA-DPA1*01:03+HLA-DPA1*02:01^HLA-DPB1*01:01+HLA-DPB1*16:01"
#' GL_string_donor <- "HLA-A*03:01+HLA-A*30:01^HLA-C*07:02+HLA-C*12:03^HLA-B*07:02+HLA-B*38:01^HLA-DRB3*01:01^HLA-DRB5*01:01^HLA-DRB1*03:01+HLA-DRB1*15:01^HLA-DQA1*01:02+HLA-DQA1*05:01^HLA-DQB1*02:01+HLA-DQB1*06:02^HLA-DPA1*01:03+HLA-DPA1*01:03^HLA-DPB1*04:01+HLA-DPB1*04:01"
#' locus <- "A"
#' result <- HLA_mismatch_HvG(GL_string_recip, GL_string_donor, locus)
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stats na.omit


HLA_mismatch_HvG <- function(GL_string_recip, GL_string_donor, loci) {
  # Check for ambiguity
  if (str_detect(GL_string_recip, "[|/]") | str_detect(GL_string_donor, "[|/]")) {
    stop("HLA_mismatch_HvG does not support ambiguous GL strings that contain the delimiters | or /")
  }

  # Normalize the loci input
  loci <- gsub("HLA_", "", loci)  # Remove HLA_ if present
  loci <- gsub("HLA-", "", loci)  # Remove HLA- if present

  # Process recipient and donor GL strings
  recip_data <- GLstring_expand_longer(GL_string_recip)
  donor_data <- GLstring_expand_longer(GL_string_donor)

  # Initialize list to store mismatch results
  mismatch_results <- list()

  # Check mismatch for each locus
  for (locus in loci) {
    full_locus <- paste0("HLA-", locus)

    # Check if the specified loci exist in both
    if (!(full_locus %in% recip_data$locus) | !(full_locus %in% donor_data$locus)) {
      stop(paste("Locus", full_locus, "not found in both recipient and donor data."))
    }

    # Filter data for the specified loci
    recip_locus_data <- recip_data %>% filter(locus == full_locus)
    donor_locus_data <- donor_data %>% filter(locus == full_locus)

    # Extract unique alleles for loci
    recip_alleles <- unique(recip_locus_data$value)
    donor_alleles <- unique(donor_locus_data$value)

    # Check mismatch
    mismatch <- any(!donor_alleles %in% recip_alleles)
    mismatch_results[[locus]] <- mismatch
  }

  # Return result
  if (length(loci) == 1) {
    return(mismatch_results[[loci]])
  } else {
    return(paste(sapply(names(mismatch_results), function(locus) {
      paste0(locus, ":", mismatch_results[[locus]])
    }), collapse = ","))
  }
}
