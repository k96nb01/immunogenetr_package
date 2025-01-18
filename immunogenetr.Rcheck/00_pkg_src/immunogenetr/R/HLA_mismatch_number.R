#' @title HLA_mismatch_number
#'
#' @description Calculates the number of mismatched HLA alleles between a
#' recipient and a donor across specified loci. Supports mismatch calculations
#' for host-vs-graft (HvG), graft-vs-host (GvH), or bidirectional mismatches.
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
#' @return An integer value or a character string:
#' - If `loci` includes only one locus, the function returns an integer
#'mismatch count for that locus.
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
#' mismatch_count_HvG <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#' print(mismatch_count_HvG)
#'
#' # Calculate mismatch numbers (Graft vs. Host)
#' mismatch_count_GvH <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#' print(mismatch_count_GvH)
#'
#' # Calculate mismatch numbers (Bidirectional)
#' mismatch_count_bidirectional <- HLA_mismatch_number(GL_string_recip, GL_string_donor,
#' loci, direction = "bidirectional")
#' print(mismatch_count_bidirectional)
#'
#' @export
#'


HLA_mismatch_number <- function(GL_string_recip, GL_string_donor, loci, direction = c("HvG", "GvH", "bidirectional"), homozygous_count = 2) {
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))

  # Compute mismatch strings for both HvG and GvH
  mismatch_HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "HvG", homozygous_count)
  mismatch_GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, "GvH", homozygous_count)

  # Helper function to count mismatches per locus
  count_mismatches <- function(mismatch_string) {
    if (is.na(mismatch_string) || mismatch_string == "NA") {
      return(0L)
    }
    alleles <- unlist(strsplit(mismatch_string, "\\+"))
    return(as.integer(length(alleles)))
  }

  # Calculate mismatch counts for each locus
  calculate_mismatch_counts <- function(mismatch_result, loci) {
    if (length(loci) == 1) {
      return(as.integer(count_mismatches(mismatch_result)))
    } else {
      # Split the result by loci and count mismatches for each
      locus_mismatches <- strsplit(mismatch_result, ", ")[[1]]
      counts <- sapply(locus_mismatches, function(x) {
        locus_parts <- strsplit(x, "=")[[1]]
        if (length(locus_parts) == 2) {
          count_mismatches(locus_parts[2])
        } else {
          0
        }
      })
      names(counts) <- loci
      # Format the output for multiple loci
      return(paste(paste0(names(counts), "=", counts), collapse = ", "))
    }
  }

  # Process mismatch counts for both directions
  mismatch_count_HvG <- calculate_mismatch_counts(mismatch_HvG, loci)
  mismatch_count_GvH <- calculate_mismatch_counts(mismatch_GvH, loci)

  # Handle directions
  if (direction == "HvG") {
    return(mismatch_count_HvG)
  } else if (direction == "GvH") {
    return(mismatch_count_GvH)
  } else if (direction == "bidirectional") {
    if (length(loci) == 1) {
      return(as.integer(max(mismatch_count_HvG, mismatch_count_GvH, na.rm = TRUE)))
    } else {
      HvG_counts <- sapply(strsplit(mismatch_count_HvG, ", ")[[1]], function(x) as.integer(strsplit(x, "=")[[1]][2]))
      GvH_counts <- sapply(strsplit(mismatch_count_GvH, ", ")[[1]], function(x) as.integer(strsplit(x, "=")[[1]][2]))
      max_counts <- pmax(HvG_counts, GvH_counts, na.rm = TRUE)
      return(paste(paste0(loci, "=", max_counts), collapse = ", "))
    }
  }

  stop("Invalid direction") # This should not be reached due to match.arg
}
