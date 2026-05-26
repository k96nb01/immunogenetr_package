#' @title GLstring_genes_expanded
#'
#' @description This function processes a specified column in a data frame
#' that contains GL strings. It separates the GL strings, identifies the HLA
#' loci, and transforms the data into a wider format with loci as column names.
#' It also creates multiple rows to separate each locus in the allele.
#'
#' @param data A data frame containing GL strings for HLA data.
#' @param gl_string The name of the column in the data frame that contains
#' GL strings.
#'
#' @return A data frame with expanded columns, where each row has a single
#' allele for a specific locus.
#'
#' @examples
#'
#' file <- HLA_typing_1[, -1]
#' GL_string <- data.frame("GL_string" = HLA_columns_to_GLstring(
#'   file,
#'   HLA_typing_columns = everything()
#' ))
#' GL_string <- GL_string[1, , drop = FALSE] # When considering first patient
#' result <- GLstring_genes_expanded(GL_string, "GL_string")
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr bind_rows
#' @importFrom tibble as_tibble
#' @importFrom tidyselect all_of
#' @importFrom stringi stri_split_fixed


GLstring_genes_expanded <- function(data, gl_string) {
  # Validate input.
  check_data_frame(data, "data")

  # -------------------------------------------------------------------------
  # Iteration 7 rewrite: replace the v1 pipeline
  #   GLstring_genes -> pivot_longer -> mutate -> separate_rows ->
  #   pivot_wider(values_fn = list) -> unnest
  # with a per-row split + rep_len recycle + bind_rows.
  #
  # The v1 pipeline only works for single-row inputs: when rows have
  # different allele counts per locus, unnest() fails ("can't recycle
  # input of size X to size Y"). v2 preserves the single-row semantics
  # exactly (including the "recycle length-1 to match max" behaviour that
  # the test file calls out as intentional) and handles multi-row input
  # by row-binding per-row expansions, which v1 couldn't do in general.
  # -------------------------------------------------------------------------

  # First pass — get the wide per-locus layout (one column per unique
  # locus across the input, each cell a GL-string fragment for that row).
  wide <- GLstring_genes(data, all_of(gl_string))

  # Per-row expansion. For each row:
  #   1. Take each locus column's fragment (e.g. "HLA-A*01:01+HLA-A*02:01").
  #   2. Split it on "+" into individual allele strings.
  #   3. Recycle columns so they all have the same number of alleles per
  #      row (matches v1's unnest behaviour: length-1 cells are recycled
  #      up to the max allele count in that row).
  #   4. Strip the "HLA-" / "HLA_" prefix from the column names.
  expanded_rows <- lapply(seq_len(nrow(wide)), function(i) {
    row_vals <- as.list(wide[i, , drop = FALSE])

    # Split each cell on "+". Missing / empty cells become a single NA so
    # they survive the row (same shape v1's NA cells produced).
    col_alleles <- lapply(row_vals, function(cell) {
      if (length(cell) == 0L) return(NA_character_)
      x <- cell[[1L]]
      if (is.na(x) || !nzchar(x)) return(NA_character_)
      stri_split_fixed(x, "+")[[1L]]
    })

    n_per_col <- lengths(col_alleles)
    max_len   <- max(n_per_col)

    # Recycle each column to max_len. rep_len replicates a length-1
    # vector to fill max_len cells, which is the only recycling case v1's
    # unnest() supported without erroring. Exact-length vectors pass
    # through; longer/mismatched lengths fall back to rep_len's usual
    # behaviour (cycle with warning) — same "best effort" semantics as v1.
    recycled <- lapply(col_alleles, function(v) {
      if (length(v) == max_len) v
      else rep_len(v, max_len)
    })

    # Strip the HLA- / HLA_ prefix so result columns are short locus
    # names ("A", "B", "DRB1" etc) as v1 did via gsub on locus.
    names(recycled) <- gsub("HLA-|HLA_", "", names(recycled))

    as.data.frame(recycled, stringsAsFactors = FALSE)
  })

  # Row-bind per-row results. bind_rows fills NA for loci absent from a
  # given row's column set, which matches the tibble-friendly behaviour
  # expected by downstream code.
  as_tibble(bind_rows(expanded_rows))
}

globalVariables(c("alleles", "everything"))
