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
#' has_mismatch <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "GvH")
#' print(has_mismatch)
#' # Output: TRUE
#'
#' @export
#'

HLA_mismatch_logical <- function(GL_string_recip, GL_string_donor, loci, direction = c("HvG", "GvH", "bidirectional"), homozygous_count = 2) {
  direction <- match.arg(direction, c("HvG", "GvH", "bidirectional"))

  # Helper function to determine logical results
  mismatch_to_logical <- function(mismatch_number) {
    if (length(loci) == 1) {
      return(mismatch_number != 0)
    } else {
      # Convert mismatch counts to logicals for multiple loci
      locus_results <- strsplit(mismatch_number, ", ")[[1]]
      logical_results <- sapply(locus_results, function(x) {
        locus_parts <- strsplit(x, "=")[[1]]
        if (length(locus_parts) == 2) {
          locus_name <- locus_parts[1]
          mismatch_count <- as.integer(locus_parts[2])
          return(paste0(locus_name, "=", mismatch_count != 0))
        } else {
          return(paste0(x, "=FALSE"))
        }
      })
      return(paste(logical_results, collapse = ", "))
    }
  }

  # Get mismatch counts using HLA_mismatch_number
  mismatch_counts <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction, homozygous_count)

  # Convert mismatch counts to logical results
  logical_results <- mismatch_to_logical(mismatch_counts)

  return(logical_results)
}
