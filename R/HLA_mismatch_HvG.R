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
#' @example inst/examples/HLA_mismatch_HvG.R
#'
#' @export
#'
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stats na.omit


HLA_mismatch_HvG <- function(GL_string_recip, GL_string_donor, locus){
  # Normalize the locus input
  locus <- gsub("HLA_", "", locus)  # Remove HLA_ if present
  locus <- gsub("HLA-", "", locus)  # Remove HLA- if present

  # Process recipient and donor GL strings
  recip_data <- tibble(GL_string = GL_string_recip) %>%
    GLstring_genes_expanded("GL_string")
  donor_data <- tibble(GL_string = GL_string_donor) %>%
    GLstring_genes_expanded("GL_string")

  # Check if the specified locus exists in both datasets
  if (!(locus %in% names(recip_data)) | !(locus %in% names(donor_data))) {
    stop(paste("Locus", locus, "not found in both recipient and donor data."))
  }

  # Extract unique entries for the specified locus from recipient and donor data
  recip_locus_entries <- recip_data %>% pull({{ locus }}) %>% na.omit() %>% unique()
  donor_locus_entries <- donor_data %>% pull({{ locus }}) %>% na.omit() %>% unique()

  # Check for mismatch
  mismatch <- any(!donor_locus_entries %in% recip_locus_entries)
  return(mismatch)
}
