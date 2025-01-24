#' @title HLA_match_summary_HCT
#'
#' @description Calculates the match summary for either the HLA-A, B, C and DRB1
#' loci (out-of-8 matching) or the HLA-A, B, C, DRB1 and DQB1 loci (out-of-10 matching),
#' as is commonly used for hematopoietic cell transplantation (HCT). Homozygous
#' mismatches are counted twice. Bidirectional matching is the default, but can
#' be overridden with the "direction" argument.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype,
#' and minimally containing the HLA-A, B, C and DRB1 loci (for Xof8 matching)
#' or the HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).
#' @param GL_string_donor A GL string representing the donor's HLA genotype,
#' and minimally containing the HLA-A, B, C and DRB1 loci (for Xof8 matching)
#' or the HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).
#' @param direction "GvH", "HvG" or "bidirectional".
#' @param match_grade "Xof8" for HLA-A, B, C and DRB1 matching or "Xof10" for
#' HLA-A, B, C, DRB1 and DQB1 matching.
#'
#' @return An integer value of the match grade summary.
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

HLA_match_summary_HCT <- function(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade){
  if (match_grade == "Xof8") {
    if (direction == "HvG") {
      match_table <- tibble(matches = HLA_match_number_HvG(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    } else if (direction == "GvH") {
      match_table <- tibble(matches = HLA_match_number_GvH(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    } else if (direction == "bidirectional") {
      match_table <- tibble(matches = HLA_match_number_bidirectional(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    }
  } else if (match_grade == "Xof10") {
    if (direction == "HvG") {
      match_table <- tibble(matches = HLA_match_number_HvG(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1", "HLA-DQB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    } else if (direction == "GvH") {
      match_table <- tibble(matches = HLA_match_number_GvH(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1", "HLA-DQB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    } else if (direction == "bidirectional") {
      match_table <- tibble(matches = HLA_match_number_bidirectional(GL_string_recip, GL_string_donor, c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1", "HLA-DQB1"))) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(matches, delim = ", ") %>%
        separate_wider_delim(matches, delim = "=", names = c("locus", "matches")) %>%
        # Recode matches as integers
        mutate(matches = as.integer(matches)) %>%
        # Add up matches
        mutate(match_sum = sum(matches), .by = case) %>%
        # Summarize and return the vector of match_sum
        distinct(case, match_sum)
      return(match_table$match_sum)
    }
  }
}


