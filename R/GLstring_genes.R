#' @title GLstring_genes
#'
#' @description This function processes a specified column in a data frame
#' that contains GL strings. It separates the GL strings, identifies the HLA
#' loci, and transforms the data into a wider format with loci as column names.
#'
#' @param data A data frame
#' @param gl_string The name of the column in the data frame that contains
#' GL strings
#'
#' @return A data frame with GL strings separated, loci identified, and data
#' transformed to a wider format with loci as columns.
#'
#' @examples
#'
#' file <- HLA_typing_1[, -1]
#' GL_string <- data.frame("GL_string" = HLA_columns_to_GLstring(
#'   file,
#'   HLA_typing_columns = everything()
#' ))
#' GL_string <- GL_string[1, , drop = FALSE] # When considering first patient
#' result <- GLstring_genes(GL_string, "GL_string")
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom tibble as_tibble
#' @importFrom stringi stri_split_fixed


GLstring_genes <- function(data, gl_string) {
  # Validate input.
  check_data_frame(data, "data")

  # Resolve tidyselect to a single column name.
  col2mod <- names(select(data, {{ gl_string }}))

  # -------------------------------------------------------------------------
  # Iteration 7 rewrite: replace the
  #   separate_longer_delim -> rename -> mutate(str_extract) -> pivot_wider
  # chain with a direct stri_split_fixed + per-locus column build. The v1
  # pipeline paid for a tidyr unchop (separate_longer_delim) and a generic
  # pivot_wider round-trip just to regroup row-level GL strings by locus.
  # v2 does both in a single C-backed split + a vectorised locus-name
  # extraction.
  # -------------------------------------------------------------------------

  n_rows  <- nrow(data)
  gl_vec  <- data[[col2mod]]

  # Split each row's GL string at "^" — one C call for the whole vector.
  # Each list element is the per-row set of locus-GL-strings.
  split_list <- stri_split_fixed(gl_vec, "^")
  n_per_row  <- lengths(split_list)

  # Flatten to long form, tracking which row each piece came from.
  flat_pieces <- unlist(split_list, use.names = FALSE)
  row_idx     <- rep.int(seq_len(n_rows), n_per_row)

  # Extract the locus name — everything before the "*" — via regexpr + substr.
  # v1's regex was "[[:alnum:]-]+(?=\\*)", which is equivalent to "take the
  # alnum/dash run immediately before the first *". Since the piece always
  # starts with the locus token for real GL strings, "substr up to star-1"
  # gives the same result without the look-ahead.
  star_pos <- regexpr("*", flat_pieces, fixed = TRUE)
  # Coerce to plain logical: regexpr on NA input returns NA_integer_, and
  # NA subscripts are illegal in `[<-`. This only counts "real match" cells.
  has_star <- !is.na(star_pos) & star_pos != -1L
  locus    <- rep(NA_character_, length(flat_pieces))
  locus[has_star] <- substr(flat_pieces[has_star], 1L, star_pos[has_star] - 1L)

  # Determine the unique locus set in first-appearance order — pivot_wider
  # uses first-appearance of names_from values as its column order, so we
  # match that for stable output column names.
  loci_levels <- unique(locus[!is.na(locus)])

  # Build one length-n_rows character column per unique locus. Missing
  # (row, locus) combinations stay NA — same as pivot_wider's default.
  locus_cols <- lapply(loci_levels, function(lc) {
    col <- rep(NA_character_, n_rows)
    # Non-NA locus, matching this level. In the unusual case where one row
    # produced the same locus twice (not a valid GL string), the last match
    # wins — same as pivot_wider's default without values_fn.
    idx_l <- which(!is.na(locus) & locus == lc)
    col[row_idx[idx_l]] <- flat_pieces[idx_l]
    col
  })
  names(locus_cols) <- loci_levels

  # Preserve every non-GL-string column from the input (e.g. a "patient"
  # identifier), then append the locus columns. The v1 pipeline implicitly
  # did this via separate_longer_delim's expansion and pivot_wider's
  # id_cols inference.
  preserved_names <- setdiff(names(data), col2mod)
  out <- c(
    lapply(preserved_names, function(nm) data[[nm]]),
    locus_cols
  )
  names(out) <- c(preserved_names, loci_levels)

  # Final column-name cleanup: HLA_column_repair converts "HLA-A" ->
  # "HLA_A" (tidyverse form without the asterisk), mirroring v1's chain.
  HLA_column_repair(as_tibble(out))
}

globalVariables(c("."))
