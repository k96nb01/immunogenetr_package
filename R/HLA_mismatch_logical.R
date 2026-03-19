#' @title HLA_mismatch_logical
#'
#' @description Determines if there are any mismatches between recipient and
#' donor HLA alleles for the specified loci. Returns `TRUE` if mismatches are
#' present, and `FALSE` otherwise.
#'
#' @param GL_string_recip A GL strings representing the recipient's HLA genotypes.
#' @param GL_string_donor A GL strings representing the donor's HLA genotypes.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional"
#' (if either "HvG" or "GvH" is TRUE), or "SOT" (host vs. graft, as is used for
#' mismatching in solid organ transplantation).
#'
#' @return A logical value (`TRUE` or `FALSE`):
#' - `TRUE` if there are mismatches between recipient and donor HLA alleles.
#' - `FALSE` if there are no mismatches.
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
#' mismatches <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#' print(mismatches)
#'
#' @export
#'

HLA_mismatch_logical <- function(GL_string_recip, GL_string_donor, loci, direction) {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)

  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional", "SOT"))

  # Determine which direction(s) need to be computed.
  # HvG and SOT only need the HvG direction; GvH only needs GvH.
  # Bidirectional needs both to take the logical OR.
  need_HvG <- (direction == "HvG" | direction == "SOT" | direction == "bidirectional")
  need_GvH <- (direction == "GvH" | direction == "bidirectional")

  # Code to determine mismatch if a single locus was supplied.
  if (length(loci) == 1) {
    # Only compute the direction(s) we actually need.
    if (need_HvG) {
      HvG <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG"))
    }
    if (need_GvH) {
      GvH <- !is.na(HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH"))
    }
    # Return the result for the requested direction.
    if (direction == "HvG" | direction == "SOT") {
      return(HvG)
    } else if (direction == "GvH") {
      return(GvH)
    } else {
      # Bidirectional: TRUE if either direction has a mismatch.
      return(HvG | GvH)
    }
  } else {
    # Code to determine mismatch if multiple loci were supplied.
    # Helper to build a logical mismatch table from HLA_mismatch_base output.
    build_mm_table <- function(base_direction, col_name) {
      tibble(raw = HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, base_direction)) %>%
        # Add a row number to combine data at the end.
        mutate(case = row_number()) %>%
        # Separate the loci.
        separate_longer_delim(raw, delim = ", ") %>%
        separate_wider_delim(raw, delim = "=", names = c("locus", "mismatches")) %>%
        # Recode NA values to ensure accurate matching.
        mutate(mismatches = na_if(mismatches, "NA")) %>%
        # Determine if any mismatches are present.
        mutate(!!col_name := !is.na(mismatches)) %>%
        # Clean up table.
        select(-mismatches)
    }

    # Only build the table(s) we actually need.
    if (direction == "bidirectional") {
      # Bidirectional needs both directions, joined together.
      HvG_table <- build_mm_table("HvG", "HvG_MM")
      GvH_table <- build_mm_table("GvH", "GvH_MM")
      # Join and take the logical OR of both directions.
      MM_table <- HvG_table %>%
        left_join(GvH_table, join_by(locus, case)) %>%
        mutate(bidirectional = HvG_MM | GvH_MM)
      result_col <- "bidirectional"
    } else if (direction == "HvG" | direction == "SOT") {
      # Only need HvG direction.
      MM_table <- build_mm_table("HvG", "HvG_MM")
      result_col <- "HvG_MM"
    } else {
      # Only need GvH direction.
      MM_table <- build_mm_table("GvH", "GvH_MM")
      result_col <- "GvH_MM"
    }

    # Format the result as "Locus1=TRUE/FALSE, Locus2=TRUE/FALSE, ..." strings.
    MM_table <- MM_table %>%
      select(locus, case, all_of(result_col)) %>%
      unite(locus, all_of(result_col), col = "MM", sep = "=") %>%
      summarise(MM = str_flatten(MM, collapse = ", "), .by = case)

    return(MM_table$MM)
  }
}

globalVariables(c("HvG_MM", "GvH_MM", ":="))
