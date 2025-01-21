#' @title HLA_mismatch_logical
#'
#' @description Determines if there are any mismatches between recipient and
#' donor HLA alleles for the specified loci. Returns `TRUE` if mismatches are
#' present, and `FALSE` otherwise.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), or
#' "bidirectional" (max of "HvG" and "GvH").
#' @param homozygous_count An integer specifying how to handle homozygosity.
#' Defaults to 2, where homozygous alleles are treated as duplicated for
#' mismatch calculations. Can be specified to be 1, in which case homozygous
#' alleles are treated as single occurrences without duplication.
#'
#' @return A logical value (`TRUE` or `FALSE`):
#' - `TRUE` if there are mismatches between recipient and donor HLA alleles.
#' - `FALSE` if there are no mismatches.
#'
#' @examples
#' # Example recipient and donor GL strings
#' GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
#' GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-DRB3*03:01"
#'
#' # Check if there are mismatches for HLA-A (Graft vs. Host)
#' has_mismatch <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci =
#' "HLA-A", direction = "GvH")
#' print(has_mismatch)
#' # Output: TRUE
#'
#' @export
#'

HLA_mismatch_logical <- function(GL_string_recip, GL_string_donor, loci, direction = c("HvG", "GvH", "bidirectional"), homozygous_count = 2) {
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))
  # Code to determine mismatch if a single locus was supplied.
  if (length(loci) == 1) {
    # Determine mismatches for both directions.
    HvG <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count))
    GvH <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count))
    # Make a tibble with the results and determine bidirectional mismatch.
    MM_table <- tibble(HvG, GvH) %>%
      mutate(bidirectional = HvG | GvH)
    # Return the result based on the direction argument.
    if (direction == "HvG"){
      return(MM_table$HvG)
    } else if (direction == "GvH"){
      return(MM_table$GvH)
    } else if (direction == "bidirectional"){
      return(MM_table$bidirectional)
    }
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
      # Determine if any mismatches are present.
      mutate(HvG_MM = !is.na(mismatches)) %>%
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
      # Determine if any mismatches are present.
      mutate(GvH_MM = !is.na(mismatches)) %>%
      # Clean up table.
      select(-mismatches)

    # Join the GvH and HvG tables
    MM_table <- HvG_table %>% left_join(GvH_table, join_by(locus, case)) %>%
      # Determine bidirectional mismatch number.
      mutate(bidirectional = HvG_MM | GvH_MM)

    # Return appropriate direction.
    # HvG
    if (direction == "HvG") {
      MM_table <- MM_table %>%
        select(locus, case, HvG_MM) %>%
        unite(locus, HvG_MM, col = "MM", sep = "=") %>%
        summarise(MM = str_flatten(MM, collapse = ", "), .by = case)
      # GvH
    } else if (direction == "GvH") {
      MM_table <- MM_table %>%
        select(locus, case, GvH_MM) %>%
        unite(locus, GvH_MM, col = "MM", sep = "=") %>%
        summarise(MM = str_flatten(MM, collapse = ", "), .by = case)
      # Bidirectional
    } else if (direction == "bidirectional") {
      MM_table <- MM_table %>%
        select(locus, case, bidirectional) %>%
        unite(locus, bidirectional, col = "MM", sep = "=") %>%
        summarise(MM = str_flatten(MM, collapse = ", "), .by = case)
    }

    return(MM_table$MM)
  }
}
