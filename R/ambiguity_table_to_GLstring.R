#' @title ambiguity_table_to_GLstring
#'
#' @description A function that converts a data table of HLA allele ambiguities
#' (e.g. as created by `GLstring_expand_longer` or `GLstring_to_ambiguity_table`)
#' into a GL string format. The function processes the table by combining allele
#' ambiguities, haplotypes, gene copies, and loci into a structured GL string.
#'
#' @param data A data frame containing columns that represent possible gene
#' locations, loci, genotype ambiguities, genotypes, and haplotypes.
#'
#' @param remove_duplicates A logical value indicating if the function will check
#' for duplicate entries at each step and remove them before assembling the final
#' GL string. Useful if the ambiguity table has been altered, for example by
#' truncating allele designations. Default is FALSE.
#'
#' @return A GL string representing the combined gene locations, loci, genotype
#' ambiguities, genotypes, and haplotypes.
#'
#' @examples
#' # Example data frame input
#' data <- tibble::tribble(
#'   ~value, ~entry, ~possible_gene_location,
#'   ~locus, ~genotype_ambiguity, ~genotype, ~haplotype, ~allele,
#'   "HLA-A*01:01:01:01", 1, 1,
#'   1, 1, 1, 1, 1,
#'   "HLA-A*01:02", 1, 1,
#'   1, 1, 1, 1, 2,
#'   "HLA-A*01:03", 1, 1,
#'   1, 1, 1, 1, 3,
#'   "HLA-A*01:95", 1, 1,
#'   1, 1, 1, 1, 4,
#'   "HLA-A*24:02:01:01", 1, 1,
#'   1, 1, 2, 1, 1,
#'   "HLA-A*01:01:01:01", 1, 1,
#'   1, 2, 1, 1, 1,
#'   "HLA-A*01:03", 1, 1,
#'   1, 2, 1, 1, 2,
#'   "HLA-A*24:03:01:01", 1, 1,
#'   1, 2, 2, 1, 1,
#'   "HLA-B*07:01:01", 1, 1,
#'   2, 1, 1, 1, 1,
#'   "B*15:01:01", 1, 1,
#'   2, 1, 2, 1, 1,
#'   "B*15:02:01", 1, 1,
#'   2, 1, 2, 1, 2,
#'   "B*07:03", 1, 1,
#'   2, 2, 1, 1, 1,
#'   "B*15:99:01", 1, 1,
#'   2, 2, 2, 1, 1,
#'   "HLA-DRB1*03:01:02", 1, 1,
#'   3, 1, 1, 1, 1,
#'   "HLA-DRB5*01:01:01", 1, 1,
#'   3, 1, 1, 2, 1,
#'   "HLA-KIR2DL5A*0010101", 1, 1,
#'   3, 1, 2, 1, 1,
#'   "HLA-KIR2DL5A*0010201", 1, 1,
#'   3, 1, 3, 1, 1,
#'   "HLA-KIR2DL5B*0010201", 1, 2,
#'   1, 1, 1, 1, 1,
#'   "HLA-KIR2DL5B*0010301", 1, 2,
#'   1, 1, 2, 1, 1
#' )
#'
#' ambiguity_table_to_GLstring(data)
#'
#' @export

ambiguity_table_to_GLstring <- function(data, remove_duplicates = FALSE) {
  # Validate inputs — identical error shape to v1.
  check_data_frame(data, "data")
  check_logical_flag(remove_duplicates, "remove_duplicates")

  # -------------------------------------------------------------------------
  # Iteration 7 rewrite: replace the six chained dplyr summarise(str_flatten)
  # passes with a single helper that sorts + run-length-encodes + pastes.
  # Each level of the GL hierarchy becomes one call to collapse_level(); the
  # integer index vectors are carried forward in-place.
  # -------------------------------------------------------------------------

  # Collapse one level of the GL hierarchy:
  #   - values: current leaf (or collapsed) strings
  #   - keys:   list of integer vectors forming the composite grouping key,
  #             outermost first. All vectors have the same length as values.
  #   - sep:    the GL separator for this level (e.g. "/" for alleles).
  #   - already_sorted: if TRUE, skip the initial lexicographic sort. This
  #     is safe to pass after the first collapse: once data is sorted by
  #     (k1, k2, ..., kN) it is still sorted by any prefix of that tuple,
  #     which is exactly how the GL-hierarchy keys are truncated level by
  #     level. Skipping the redundant sorts is the single biggest memory
  #     saving in this rewrite.
  # Returns a list $value (collapsed strings) and $keys (truncated key list).
  collapse_level <- function(values, keys, sep, remove_duplicates, already_sorted = FALSE) {
    n <- length(values)
    if (n == 0L) {
      return(list(value = character(0), keys = rep(list(integer(0)), length(keys))))
    }

    if (!already_sorted) {
      # Sort by the composite key, outermost first. do.call(order, keys)
      # applies order()'s multi-argument form: the first vector in `keys`
      # is the primary sort key, subsequent vectors break ties.
      ord    <- do.call(order, keys)
      values <- values[ord]
      keys   <- lapply(keys, function(k) k[ord])
    }

    # Build a boolean "row starts a new run" vector. A run ends whenever ANY
    # component of the composite key changes between adjacent rows. We OR
    # together the per-component changes: position 1 is always TRUE (start
    # of data), and for subsequent positions we compare k[i] vs k[i - 1].
    changed <- logical(n)
    changed[1L] <- TRUE
    for (k in keys) {
      changed <- changed | c(TRUE, k[-1L] != k[-n])
    }
    # Integer run id: cumsum of the TRUE markers gives each row its group.
    run_id <- cumsum(changed)

    # Optional: drop duplicated (run, value) pairs inside each group before
    # pasting. v1 did this via distinct() on (value, by_cols); this is the
    # same semantics because run_id encodes the group identity exactly.
    if (remove_duplicates) {
      combined <- paste(run_id, values, sep = "\x01")
      keep     <- !duplicated(combined)
      values   <- values[keep]
      run_id   <- run_id[keep]
      keys     <- lapply(keys, function(k) k[keep])
    }

    # Paste values within each run. split() on an integer run_id preserves
    # ascending run order, which matches the sorted key order — so we can
    # assemble the collapsed vector in place.
    #
    # NA semantics: v1 used stringr::str_flatten which returns NA if any
    # element in the group is NA. Plain paste() converts NA to the string
    # "NA" and concatenates, which is a different (wrong) behaviour. The
    # anyNA guard reproduces str_flatten's propagation rule.
    pasted <- vapply(
      split(values, run_id),
      function(v) if (anyNA(v)) NA_character_ else paste(v, collapse = sep),
      character(1)
    )

    # For the next level up, keep one key row per run (the first, by
    # construction of the sort). duplicated(run_id) is TRUE on every row
    # except the first of each run.
    first_in_run <- !duplicated(run_id)
    new_keys <- lapply(keys, function(k) k[first_in_run])

    list(value = unname(pasted), keys = new_keys)
  }

  # Extract the column vectors once. These names are guaranteed by upstream
  # GLstring_expand_longer; the error path (missing column) surfaces naturally
  # via the $ accessor returning NULL.
  value <- data$value
  entry <- data$entry
  pgl   <- data$possible_gene_location
  locus <- data$locus
  ga    <- data$genotype_ambiguity
  geno  <- data$genotype
  hapl  <- data$haplotype

  # Level 1 — collapse alleles within the same haplotype with "/".
  r <- collapse_level(
    value,
    list(entry, pgl, locus, ga, geno, hapl),
    "/",
    remove_duplicates
  )
  value <- r$value
  entry <- r$keys[[1L]]; pgl <- r$keys[[2L]]; locus <- r$keys[[3L]]
  ga    <- r$keys[[4L]]; geno <- r$keys[[5L]]; hapl <- r$keys[[6L]]

  # Level 2 — collapse haplotypes within the same genotype with "~".
  # Data is already sorted by (entry, pgl, locus, ga, geno, hapl) from
  # level 1, so it is still sorted by the level-2 key prefix.
  r <- collapse_level(
    value,
    list(entry, pgl, locus, ga, geno),
    "~",
    remove_duplicates,
    already_sorted = TRUE
  )
  value <- r$value
  entry <- r$keys[[1L]]; pgl <- r$keys[[2L]]; locus <- r$keys[[3L]]
  ga    <- r$keys[[4L]]; geno <- r$keys[[5L]]

  # Level 3 — collapse genotypes within the same genotype-ambiguity set
  # with "+" (the gene-copy separator). Still sorted from level 1.
  r <- collapse_level(
    value,
    list(entry, pgl, locus, ga),
    "+",
    remove_duplicates,
    already_sorted = TRUE
  )
  value <- r$value
  entry <- r$keys[[1L]]; pgl <- r$keys[[2L]]; locus <- r$keys[[3L]]
  ga    <- r$keys[[4L]]

  # Level 4 — collapse genotype ambiguities within the same locus with "|".
  r <- collapse_level(
    value,
    list(entry, pgl, locus),
    "|",
    remove_duplicates,
    already_sorted = TRUE
  )
  value <- r$value
  entry <- r$keys[[1L]]; pgl <- r$keys[[2L]]; locus <- r$keys[[3L]]

  # Level 5 — collapse loci within the same possible-gene-location with "^".
  r <- collapse_level(
    value,
    list(entry, pgl),
    "^",
    remove_duplicates,
    already_sorted = TRUE
  )
  value <- r$value
  entry <- r$keys[[1L]]; pgl <- r$keys[[2L]]

  # Level 6 — collapse possible-gene-locations within the same entry with "?"
  # and flatten to one string per entry.
  r <- collapse_level(
    value,
    list(entry),
    "?",
    remove_duplicates,
    already_sorted = TRUE
  )
  # Final result: one GL string per entry, in ascending entry order (matches
  # v1's pull() output because dplyr's .by also yields first-appearance order
  # and GLstring_expand_longer always emits entries in 1..N order).
  r$value
}

globalVariables(c("."))
