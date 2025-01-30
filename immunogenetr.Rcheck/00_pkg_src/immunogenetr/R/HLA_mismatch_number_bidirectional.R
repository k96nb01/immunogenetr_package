#' @title HLA_mismatch_number_bidirectional
#'
#' @description A wrapper for `HLA_mismatch_number`: calculates the number of
#' mismatched HLA alleles between a recipient and a donor across specified loci
#' in a bidirectional manner (the max value of the GvH and HvG mismatch).
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
#' @param homozygous_count An integer specifying how to count homozygous mismatches.
#' Defaults to 2, where homozygous mismatches are treated as two mismatches,
#' regardless if one or two alleles are supplied in the GL string (in cases
#' where one allele is supplied, it is duplicated by the function). If
#' specified as 1, homozygous mismatches are only counted once, regardless of
#' whether one or two alleles are supplied in the GL string (in cases where
#' two alleles are supplied, the second identical allele is deleted).
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
#' # Calculate mismatch numbers
#' HLA_mismatch_number_bidirectional(GL_string_recip, GL_string_donor, loci)
#'
#' @export
#'


HLA_mismatch_number_bidirectional <- function(GL_string_recip, GL_string_donor, loci, homozygous_count = 2){
  # Code to determine mismatch numbers if a single locus was supplied.
  if (length(loci) == 1) {
    # Determine mismatches for both directions.
    HvG <- replace_na(str_count(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count), "(\\+|$)"), 0) # The regex matches the end of the string or a "+".
    GvH <- replace_na(str_count(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count), "(\\+|$)"), 0)
    # Make a tibble with the results and determine bidirectional mismatch.
    MM_table <- tibble(HvG, GvH) %>%
      mutate(bidirectional = pmax(HvG, GvH, na.rm = TRUE))
      return(MM_table$bidirectional)
    } else {
    # Code to determine mismatch numbers if multiple loci were supplied.
    # Determine mismatches for both directions.
    HvG_table <- tibble("HvG" = HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count)) %>%
      # Add a row number to combine data at the end.
      mutate(case = row_number()) %>%
      # Separate the loci.
      separate_longer_delim(HvG, delim = ", ") %>%
      separate_wider_delim(HvG, delim = "=", names = c("locus", "mismatches")) %>%
      # Recode NA values to ensure accurate matching.
      mutate(mismatches = na_if(mismatches, "NA")) %>%
      # Count number of mismatches.
      mutate(HvG_number = replace_na(str_count(mismatches, "(\\+|$)"), 0)) %>%
      # Clean up table.
      select(-mismatches)

    GvH_table <- tibble("GvH" = HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count)) %>%
      # Add a row number to combine data at the end.
      mutate(case = row_number()) %>%
      # Separate the loci.
      separate_longer_delim(GvH, delim = ", ") %>%
      separate_wider_delim(GvH, delim = "=", names = c("locus", "mismatches")) %>%
      # Recode NA values to ensure accurate matching.
      mutate(mismatches = na_if(mismatches, "NA")) %>%
      # Count number of mismatches.
      mutate(GvH_number = replace_na(str_count(mismatches, "(\\+|$)"), 0)) %>%
      # Clean up table.
      select(-mismatches)

    # Join the GvH and HvG tables
    MM_table <- HvG_table %>% left_join(GvH_table, join_by(locus, case)) %>%
      # Calculate bidirectional mismatch number.
      mutate(bidirectional = pmax(HvG_number, GvH_number, na.rm = TRUE))

    MM_table <- MM_table %>%
        select(locus, case, bidirectional) %>%
        unite(locus, bidirectional, col = "MM", sep = "=") %>%
        summarise(MM = str_flatten(MM, collapse = ", "), .by = case)

    return(MM_table$MM)
  }
}

globalVariables(c("mismatches", "case", "HvG_number", "GvH_number", "MM", "bidirectional"))

