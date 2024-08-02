#' @title HLA_mismatch_alleles_HvG
#'
#' @description A function that checks for any alleles in the donor that are not present in the recipient for a specified locus and returns a string of mismatched alleles.
#'
#' @param GL_string_recip GL string for the HLA data of the recipient.
#' @param GL_string_donor GL string for the HLA data of the donor.
#' @param locus The name of the locus for which the function checks for a mismatch.
#'
#' @return A string of mismatched alleles. If there are no mismatches, returns "NA".
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
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stats na.omit


HLA_mismatch_alleles_HvG <- function(GL_string_recip, GL_string_donor, loci) {
  # Check for ambiguity
  if (str_detect(GL_string_recip, "[|/]") | str_detect(GL_string_donor, "[|/]")) {
    stop("HLA_mismatch_alleles_HvG does not support ambiguous GL strings that contain the delimiters | or /")
  }

  # Normalize the loci input
  loci <- gsub("HLA_", "", loci)  # Remove HLA_ if present
  loci <- gsub("HLA-", "", loci)  # Remove HLA- if present

  # Process recipient and donor GL strings
  recip_data <- tibble(GL_string = GL_string_recip) %>%
    GLstring_genes_expanded("GL_string")
  donor_data <- tibble(GL_string = GL_string_donor) %>%
    GLstring_genes_expanded("GL_string")

  # Initialize a list to store mismatches for each locus
  mismatch_list <- list()

  for (locus in loci) {
    # Check if the specified locus exists in both datasets
    if (!(locus %in% names(recip_data)) | !(locus %in% names(donor_data))) {
      stop(paste("Locus", locus, "not found in both recipient and donor data."))
    }

    # Extract unique entries for the specified locus from recipient and donor data
    recip_locus_entries <- recip_data %>% pull({{ locus }}) %>% na.omit() %>% unique()
    donor_locus_entries <- donor_data %>% pull({{ locus }}) %>% na.omit() %>% unique()

    # Identify mismatched alleles
    mismatches <- donor_locus_entries[!donor_locus_entries %in% recip_locus_entries]

    # Store mismatches in the list
    if (length(mismatches) > 0) {
      # Create GL strings for mismatched alleles
      mismatch_list[[locus]] <- paste(mismatches, collapse = "+")
    }
  }

  # Concatenate mismatches into a single GL string
  mismatch_gl_string <- paste(unlist(mismatch_list), collapse = "^")

  # Return result
  return(mismatch_gl_string)
}
