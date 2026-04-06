#' @title HLA_mismatch_number
#'
#' @description Calculates the number of mismatched HLA alleles between a
#' recipient and a donor across specified loci. Supports mismatch calculations
#' for host-vs-graft (HvG), graft-vs-host (GvH), or bidirectional.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (the max value of "HvG" and "GvH"), or "SOT" (host vs. graft, as is used for
#' mismatching in solid organ transplantation).
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
#'
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#'
#' GL_string_recip <- GL_string[1]
#' GL_string_donor <- GL_string[2]
#'
#' loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
#'
#' # Calculate mismatch numbers (Host vs. Graft)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#'
#' # Calculate mismatch numbers (Graft vs. Host)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#'
#' # Calculate mismatch numbers (Bidirectional)
#' HLA_mismatch_number(GL_string_recip, GL_string_donor,
#'   loci,
#'   direction = "bidirectional"
#' )
#'
#' @export
#'
#' @importFrom dplyr join_by
#' @importFrom dplyr mutate
#' @importFrom dplyr summarise
#' @importFrom dplyr left_join
#' @importFrom dplyr na_if
#' @importFrom stringr str_count
#' @importFrom stringr str_flatten
#' @importFrom tidyr separate_longer_delim
#' @importFrom tidyr separate_wider_delim
#' @importFrom tidyr replace_na
#' @importFrom tibble tibble
#' @importFrom tidyr unite


HLA_mismatch_number <- function(GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2) {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)
  check_homozygous_count(homozygous_count)

  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional", "SOT"))

  # Helper to count mismatched alleles from HLA_mismatch_base output.
  # The regex "(\\+|$)" matches each allele (separated by "+" or at end of string).
  count_mismatches <- function(mismatch_str) {
    replace_na(str_count(mismatch_str, "(\\+|$)"), 0)
  }

  # Determine which direction(s) need to be computed.
  # HvG and SOT only need the HvG direction; GvH only needs GvH.
  # Bidirectional needs both to take the max.
  need_HvG <- (direction == "HvG" | direction == "SOT" | direction == "bidirectional")
  need_GvH <- (direction == "GvH" | direction == "bidirectional")

  # Code to determine mismatch numbers if a single locus was supplied.
  if (length(loci) == 1) {
    # Only compute the direction(s) we actually need.
    if (need_HvG) {
      HvG <- count_mismatches(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count))
    }
    if (need_GvH) {
      GvH <- count_mismatches(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count))
    }
    # Return the result for the requested direction.
    if (direction == "HvG" | direction == "SOT") {
      return(HvG)
    } else if (direction == "GvH") {
      return(GvH)
    } else {
      # Bidirectional: return the max of both directions.
      return(pmax(HvG, GvH, na.rm = TRUE))
    }
  } else {
    # Code to determine mismatch numbers if multiple loci were supplied.
    # Helper to build a mismatch count table from HLA_mismatch_base output.
    build_mm_table <- function(base_direction, col_name) {
      tibble(raw = HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, base_direction, homozygous_count)) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(raw, delim = ", ") %>%
        separate_wider_delim(raw, delim = "=", names = c("locus", "mismatches")) %>%
        # Recode NA values to ensure accurate counting.
        mutate(mismatches = na_if(mismatches, "NA")) %>%
        # Count number of mismatches.
        mutate(!!col_name := count_mismatches(mismatches)) %>%
        # Clean up table.
        select(-mismatches)
    }

    # Only build the table(s) we actually need.
    if (direction == "bidirectional") {
      # Bidirectional needs both directions, joined together.
      HvG_table <- build_mm_table("HvG", "HvG_number")
      GvH_table <- build_mm_table("GvH", "GvH_number")
      # Join and take the max of both directions.
      MM_table <- HvG_table %>%
        left_join(GvH_table, join_by(locus, case)) %>%
        mutate(bidirectional = pmax(HvG_number, GvH_number, na.rm = TRUE))
      result_col <- "bidirectional"
    } else if (direction == "HvG" | direction == "SOT") {
      # Only need HvG direction.
      MM_table <- build_mm_table("HvG", "HvG_number")
      result_col <- "HvG_number"
    } else {
      # Only need GvH direction.
      MM_table <- build_mm_table("GvH", "GvH_number")
      result_col <- "GvH_number"
    }

    # Format the result as "Locus1=Count1, Locus2=Count2, ..." strings.
    MM_table <- MM_table %>%
      select(locus, case, all_of(result_col)) %>%
      unite(locus, all_of(result_col), col = "MM", sep = "=") %>%
      summarise(MM = str_flatten(MM, collapse = ", "), .by = case)
    return(MM_table$MM)
  }
}

globalVariables(c(
  "mismatches", "case", "HvG_number", "GvH_number", "MM", "bidirectional", ":="
))
