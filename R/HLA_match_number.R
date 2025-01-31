#' @title HLA_match_number
#'
#' @description Calculates the number of HLA matches as two minus the number of
#' mismatches from `HLA_mismatch_number`. Homozygous mismatches are counted twice.
#' Supports match calculations for host-vs-graft (HvG), graft-vs-host (GvH),
#' or bidirectional. Bidirectional matching is the default, but can be overridden
#' using the "direction" argument.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of match.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (the minimum value of "HvG" and "GvH").
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
#' # Calculate mismatch numbers (Host vs. Graft)
#' HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#'
#' # Calculate mismatch numbers (Graft vs. Host)
#' HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#'
#' # Calculate mismatch numbers (Bidirectional)
#' HLA_match_number(GL_string_recip, GL_string_donor,
#' loci, direction = "bidirectional")
#'
#' @export
#'

HLA_match_number <- function(GL_string_recip, GL_string_donor, loci, direction = "bidirectional"){
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))
  # Code to determine match numbers if a single locus was supplied.
  if (length(loci) == 1) {
    if (direction == "HvG") {
      # Calculate matches as 2 - HvG mismatch.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "HvG")) %>%
        mutate(match = 2 - mismatch)
      return(match_table$match)
    } else if (direction == "GvH") {
      # Calculate matches as 2 - GvH mismatch.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "GvH")) %>%
        mutate(match = 2 - mismatch)
      return(match_table$match)
    } else if (direction == "bidirectional") {
      # Calculate matches as 2 - bidirectional mismatch.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "bidirectional")) %>%
        mutate(match = 2 - mismatch)
      return(match_table$match)
    }
    # Code to determine match numbers if multiple loci were supplied.
  } else {
    if (direction == "HvG") {
      # Determine mismatches for the HvG direction.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "HvG")) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(mismatch, delim = ", ") %>%
        separate_wider_delim(mismatch, delim = "=", names = c("locus", "mismatches")) %>%
        # Recode mismatches as integers
        mutate(mismatches = as.integer(mismatches)) %>%
        # Calculate matches as 2 - mismatch.
        mutate(matches = 2 - mismatches) %>%
        # Clean up table.
        select(-mismatches) %>%
        unite(locus, matches, col = "Matches", sep = "=") %>%
        summarise(Matches = str_flatten(Matches, collapse = ", "), .by = case)

      return(match_table$Matches)
    } else if (direction == "GvH") {
      # Determine mismatches for the GvH direction.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "GvH")) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(mismatch, delim = ", ") %>%
        separate_wider_delim(mismatch, delim = "=", names = c("locus", "mismatches")) %>%
        # Recode mismatches as integers
        mutate(mismatches = as.integer(mismatches)) %>%
        # Calculate matches as 2 - mismatch.
        mutate(matches = 2 - mismatches) %>%
        # Clean up table.
        select(-mismatches) %>%
        unite(locus, matches, col = "Matches", sep = "=") %>%
        summarise(Matches = str_flatten(Matches, collapse = ", "), .by = case)

      return(match_table$Matches)
    } else if (direction == "bidirectional") {
      # Determine mismatches for both directions.
      match_table <- tibble(mismatch = HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, "bidirectional")) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(mismatch, delim = ", ") %>%
        separate_wider_delim(mismatch, delim = "=", names = c("locus", "mismatches")) %>%
        # Recode mismatches as integers
        mutate(mismatches = as.integer(mismatches)) %>%
        # Calculate matches as 2 - mismatch.
        mutate(matches = 2 - mismatches) %>%
        # Clean up table.
        select(-mismatches) %>%
        unite(locus, matches, col = "Matches", sep = "=") %>%
        summarise(Matches = str_flatten(Matches, collapse = ", "), .by = case)

      return(match_table$Matches)
    }
  }
}

globalVariables(c("mismatch", "matches", "Matches"))
