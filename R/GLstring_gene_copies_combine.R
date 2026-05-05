#' @title GLstring_gene_copies_combine
#'
#' @description A function for combining two columns of typing from the same
#' locus into a single column in the appropriate GL string format.
#'
#' @param .data A data frame
#' @param columns The names of the columns in the data frame that contain typing
#' information to be combined
#' @param sample_column The name of the column that identifies samples in the
#' data frame. Default is "sample".
#'
#' @return A data frame with the specified columns combined into a single column
#' for each locus, in GL string format.
#'
#' @examples
#' library(dplyr)
#' HLA_typing_1 %>%
#'   mutate(across(A1:B2, ~ HLA_prefix_add(.))) %>%
#'   GLstring_gene_copies_combine(c(A1:B2), sample_column = patient)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom tibble as_tibble

GLstring_gene_copies_combine <- function(.data, columns, sample_column = "sample") {
  # Validate input.
  check_data_frame(.data, ".data")

  # Resolve tidyselect args to plain column-name strings. select(.data, {{ x }})
  # accepts bare symbols, strings, and tidyselect helpers, so this single
  # pattern matches what the v1 dplyr pipeline supported.
  cols2mod    <- names(select(.data, {{ columns }}))
  sample_name <- names(select(.data, {{ sample_column }}))

  # -------------------------------------------------------------------------
  # Iteration 6 rewrite: replace the pivot_longer → mutate → filter →
  # summarise → pivot_wider → rename_with round-trip with a one-pass flat
  # vector + rle aggregation. Same output shape, far less allocation.
  # -------------------------------------------------------------------------

  n_rows <- nrow(.data)
  n_cols <- length(cols2mod)

  # Flatten the allele columns into a single character vector. as.matrix
  # on a data-frame subset unrolls column-major, which is fine — we only
  # care that each cell's (row, column) is recoverable, and the row index
  # of cell k is ((k - 1) %% n_rows) + 1.
  allele_mat <- as.matrix(.data[, cols2mod, drop = FALSE])
  flat       <- as.vector(allele_mat)
  row_idx    <- rep.int(seq_len(n_rows), n_cols)

  # Extract the locus prefix (e.g. "HLA-A", "HLA-DRB1") from each cell in
  # a single vectorised regexpr call. The original pipeline did a per-cell
  # str_extract; regexpr + substr is the same operation without the
  # stringr dispatch overhead.
  m        <- regexpr("HLA-[[:alnum:]]+", flat)
  match_ok <- m != -1L
  valid    <- match_ok & !is.na(flat)
  locus    <- rep(NA_character_, length(flat))
  locus[valid] <- substr(
    flat[valid],
    m[valid],
    m[valid] + attr(m, "match.length")[valid] - 1L
  )

  # Filter to cells that produced a valid locus match. This is the
  # equivalent of the old filter(!is.na(locus)) step.
  row_v    <- row_idx[valid]
  locus_v  <- locus[valid]
  allele_v <- flat[valid]

  # Stable locus column order: first-appearance across the input.
  # pivot_wider's column order was determined by dplyr's first-appearance
  # ordering on the summarised groups; we reproduce that here by using
  # unique() on the valid-cell sequence before sorting.
  locus_levels    <- unique(locus_v)
  locus_col_names <- sub("HLA-", "HLA_", locus_levels, fixed = TRUE)

  # Integer key per (row, locus) so we can sort and rle-aggregate with
  # pure-integer ops. locus_fac maps each cell's locus to an index into
  # locus_levels; key combines row and locus into one unique integer.
  locus_fac <- match(locus_v, locus_levels)
  key       <- row_v * length(locus_levels) + locus_fac

  # Sort by key so siblings of the same (row, locus) group are contiguous.
  ord         <- order(key)
  row_s       <- row_v[ord]
  locus_fac_s <- locus_fac[ord]
  allele_s    <- allele_v[ord]

  # Run-length encode the sorted key to get group boundaries, then paste
  # the alleles in each group with "+". The per-group paste is a small
  # per-row cost; everything else is vectorised.
  r      <- rle(key[ord])
  ends   <- cumsum(r$lengths)
  starts <- c(1L, ends[-length(ends)] + 1L)
  collapsed <- vapply(
    seq_along(starts),
    function(i) paste(allele_s[starts[i]:ends[i]], collapse = "+"),
    character(1)
  )
  run_row       <- row_s[starts]
  run_locus_fac <- locus_fac_s[starts]

  # Assemble the wide output. Start with the sample column (preserved from
  # the input) and add one character column per locus. Missing (row, locus)
  # combinations stay NA — same as pivot_wider's behaviour.
  out <- list()
  out[[sample_name]] <- .data[[sample_name]]
  for (i in seq_along(locus_levels)) {
    col  <- rep(NA_character_, n_rows)
    mask <- run_locus_fac == i
    col[run_row[mask]] <- collapsed[mask]
    out[[locus_col_names[i]]] <- col
  }

  as_tibble(out)
}

globalVariables(c("locus", "allele"))
