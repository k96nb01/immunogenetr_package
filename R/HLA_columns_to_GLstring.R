#' @title HLA_columns_to_GLstring
#'
#' @description A function to take HLA typing data spread across different columns,
#' as is often found in wild-caught data, and transform it to a GL string. If column names
#' have anything besides the locus name and a number (e.g. "mA1Cd" instead of just "A1"),
#' the function will have trouble determining the locus from the column name. The `prefix_to_remove`
#' and `suffix_to_remove` arguments can be used to clean up the column names. See the example for
#' how these arguments are used.
#'
#' @param data A data frame with each row including an HLA typing result, with
#' individual columns containing a single allele.
#' @param HLA_typing_columns A list of columns containing the HLA alleles. Tidyselect is supported.
#' @param prefix_to_remove An optional string of characters to remove from the
#' locus names. The goal is to get the column names to the locus and a number. For example,
#' columns named "mDRB11Cd" and "mDRB12Cd" should use the `prefix_to_remove` value of "m".
#' @param suffix_to_remove An optional string of characters to remove from the
#' locus names. Using the example above, the `suffix_to_remove` value will be "Cd".
#'
#' @return A list of GL strings in the order of the original data frame.
#'
#' @examples
#' # The HLA_typing_LIS dataset contains a table as might be found in a clinical laboratory
#' # information system:
#' print(HLA_typing_LIS)
#'
#' # The `HLA_columns_to_GLString` function can be used to coerce typing spread across
#' # multiple columns into a GL string:
#' library(dplyr)
#' HLA_typing_LIS %>%
#'   mutate(
#'     GL_string = HLA_columns_to_GLstring(
#'       ., # Note that if this function is used inside a `mutate` call "." will have to be
#'       # used as the first argument to extract data from the working data frame.
#'       HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'       prefix_to_remove = "m",
#'       suffix_to_remove = "Cd.recipient"
#'     ),
#'     .after = patient
#'   ) %>%
#'   select(patient, GL_string)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom cli cli_abort
#' @importFrom stringi stri_startswith_fixed stri_endswith_fixed

HLA_columns_to_GLstring <- function(data, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "") {
  # Validate the data frame input up-front.
  check_data_frame(data, "data")

  # Resolve the tidyselect argument to a character vector of column names.
  col2mod <- names(select(data, {{ HLA_typing_columns }}))

  n_rows <- nrow(data)
  n_cols <- length(col2mod)
  if (n_cols == 0L) {
    cli_abort("{.arg HLA_typing_columns} did not select any columns.")
  }

  # -------------------------------------------------------------------------
  # Iteration 6 rewrite: build the GL strings with a single vectorised pass
  # over a flattened allele matrix instead of the previous pivot_longer ->
  # 12-stage mutate pipeline -> two summarise/str_flatten joins. Every
  # column-level decision (locus name, serologic map, "always molecular"
  # flag) is computed once per column rather than once per cell.
  # -------------------------------------------------------------------------

  # --- Per-column setup (O(n_cols)) -----------------------------------------

  # Strip the optional user-supplied prefix and suffix from each column name
  # case-insensitively using stringi's fixed-string prefix/suffix matchers.
  # This avoids the regex-escape + stringr round-trip that v1 used.
  trunc_names <- col2mod
  if (nzchar(prefix_to_remove)) {
    starts <- stringi::stri_startswith_fixed(trunc_names, prefix_to_remove, case_insensitive = TRUE)
    trunc_names[starts] <- substr(
      trunc_names[starts],
      nchar(prefix_to_remove) + 1L,
      nchar(trunc_names[starts])
    )
  }
  if (nzchar(suffix_to_remove)) {
    ends <- stringi::stri_endswith_fixed(trunc_names, suffix_to_remove, case_insensitive = TRUE)
    trunc_names[ends] <- substr(
      trunc_names[ends],
      1L,
      nchar(trunc_names[ends]) - nchar(suffix_to_remove)
    )
  }
  # Strip any leading "HLA-" / locus prefix while keeping the locus itself.
  trunc_names <- HLA_prefix_remove(trunc_names, keep_locus = TRUE)
  lower_names <- tolower(trunc_names)

  # Per-column locus lookup via prefix-match cascade. Order matters:
  # more specific prefixes (e.g. "bw" before "b", "drb345" before "drb3",
  # "dqb1" before "dq") must come first. Done once per column, not once
  # per cell as v1 did inside its case_when.
  locus_from_name <- vapply(lower_names, function(nm) {
    if      (startsWith(nm, "a"))      "HLA-A"
    else if (startsWith(nm, "bw"))     "HLA-Bw"
    else if (startsWith(nm, "b"))      "HLA-B"
    else if (startsWith(nm, "cw"))     "HLA-Cw"
    else if (startsWith(nm, "c"))      "HLA-C"
    else if (startsWith(nm, "drb345")) "HLA-DRB345"
    else if (startsWith(nm, "drb1"))   "HLA-DRB1"
    else if (startsWith(nm, "drb3"))   "HLA-DRB3"
    else if (startsWith(nm, "drb4"))   "HLA-DRB4"
    else if (startsWith(nm, "drb5"))   "HLA-DRB5"
    else if (startsWith(nm, "dr"))     "HLA-DR"
    else if (startsWith(nm, "dqb1"))   "HLA-DQB1"
    else if (startsWith(nm, "dqa1"))   "HLA-DQA1"
    else if (startsWith(nm, "dq"))     "HLA-DQ"
    else if (startsWith(nm, "dpa1"))   "HLA-DPA1"
    else if (startsWith(nm, "dpb1"))   "HLA-DPB1"
    else                               "unknown"
  }, character(1), USE.NAMES = FALSE)

  # Early error — same message shape the v1 function produced.
  bad_idx <- which(locus_from_name == "unknown")
  if (length(bad_idx) > 0L) {
    cli_abort(
      "The column(s) {.val {col2mod[bad_idx]}} could not be parsed to determine HLA loci."
    )
  }

  # Serologic-name lookup map, keyed by the molecular locus names above.
  serologic_map <- c(
    "HLA-A" = "HLA-A",
    "HLA-B" = "HLA-B",
    "HLA-Bw" = "HLA-Bw",
    "HLA-C" = "HLA-Cw",
    "HLA-Cw" = "HLA-Cw",
    "HLA-DRB1" = "HLA-DR",
    "HLA-DRB345" = "HLA-DR",
    "HLA-DRB3" = "HLA-DR",
    "HLA-DRB4" = "HLA-DR",
    "HLA-DRB5" = "HLA-DR",
    "HLA-DR" = "HLA-DR",
    "HLA-DQB1" = "HLA-DQ",
    "HLA-DQA1" = "HLA-DQA",
    "HLA-DQ" = "HLA-DQ",
    "HLA-DPA1" = "HLA-DPA",
    "HLA-DPB1" = "HLA-DP"
  )
  serologic_name_col <- serologic_map[locus_from_name]

  # Columns whose alleles are always molecular regardless of format
  # (DQA1 / DPB1 / DPA1) — matches the original str_detect on column names.
  is_mol_col <- grepl("DQA1|DPB1|DPA1", col2mod)

  # --- Flatten the allele matrix to long per-cell vectors -------------------

  allele_mat <- as.matrix(data[, col2mod, drop = FALSE])
  # Column-major unrolling: cell k has row = ((k - 1) %% n_rows) + 1
  # and col = ((k - 1) %/% n_rows) + 1. We derive the explicit index vectors
  # now so every downstream step stays vectorised.
  raw     <- as.vector(allele_mat)
  row_idx <- rep.int(seq_len(n_rows), n_cols)
  col_idx <- rep(seq_len(n_cols), each = n_rows)

  # --- Per-cell transformations --------------------------------------------

  # "molecular" is decided from the RAW (pre-validate, pre-prefix-remove)
  # cell value, matching v1's str_detect(allele, ":|^0") order of
  # operations. We add the per-column "always molecular" override on top.
  has_colon        <- !is.na(raw) & grepl(":", raw, fixed = TRUE)
  has_leading_zero <- !is.na(raw) & startsWith(raw, "0")
  molecular_cell   <- has_colon | has_leading_zero | is_mol_col[col_idx]

  # Clean each cell via HLA_validate (already vectorised).
  validated <- HLA_validate(raw)

  # DRB_locus_raw: detect DRB3/4/5 hints from the allele text itself. The
  # v1 case_when had two alternatives:
  #   (1) alleles containing "DRB[345]*" (e.g. "HLA-DRB3*01:01") -> take
  #       the digit after "DRB" as the target locus.
  #   (2) alleles starting with "[345]*" -> take that leading digit.
  # We replicate the preference order: (1) wins over (2).
  drb_num_A <- rep("", length(validated))
  mA <- regexpr("DRB[345]", validated, perl = TRUE, ignore.case = TRUE)
  hasA <- mA != -1L & !is.na(mA)
  # The [345] digit sits at column offset 3 from the match start.
  drb_num_A[hasA] <- substr(
    validated[hasA],
    mA[hasA] + 3L,
    mA[hasA] + 3L
  )
  drb_num_B <- rep("", length(validated))
  hasB <- !is.na(validated) & grepl("^[345]\\*", validated)
  drb_num_B[hasB] <- substr(validated[hasB], 1L, 1L)
  drb_num <- drb_num_A
  use_B <- drb_num == "" & drb_num_B != ""
  drb_num[use_B] <- drb_num_B[use_B]
  drb_locus_raw <- rep(NA_character_, length(validated))
  drb_locus_raw[drb_num != ""] <- paste0("HLA-DRB", drb_num[drb_num != ""])

  # Strip "HLA-" / locus prefix from the cleaned allele text so the
  # assembled output re-applies them consistently. HLA_prefix_remove is
  # already vectorised and (post-iter-6) very cheap.
  allele_clean <- HLA_prefix_remove(validated)

  # DR51/52/53 detection (DRB345 flag): allele starts with "5" AND the
  # column's locus_from_name is "HLA-DR". This preserves the grouping v1
  # used to keep serologic DR5x alleles separate from the non-5x ones.
  DRB345 <- !is.na(allele_clean) &
            startsWith(allele_clean, "5") &
            locus_from_name[col_idx] == "HLA-DR"

  # Final per-cell locus: coalesce the allele-derived DRB3/4/5 hint with
  # the column-name-derived locus.
  molecular_locus <- ifelse(
    is.na(drb_locus_raw),
    locus_from_name[col_idx],
    drb_locus_raw
  )

  # --- XX logic (group by row x molecular_locus) ---------------------------
  # If every allele in a (row, locus) group is NA, emit one "XX" placeholder
  # so the locus survives the NA filter. Then drop NAs and drop "XX" rows
  # for any DRB[345] locus (which is always optional).
  grp_key       <- paste(row_idx, molecular_locus, sep = "\x01")
  grp_ix        <- match(grp_key, unique(grp_key))
  n_per_grp     <- tabulate(grp_ix)
  n_na_per_grp  <- tabulate(grp_ix[is.na(allele_clean)], nbins = length(n_per_grp))
  all_na_grp    <- n_per_grp == n_na_per_grp
  all_na_mask   <- is.na(allele_clean) & all_na_grp[grp_ix]
  allele_clean[all_na_mask] <- "XX"

  is_drb345_locus <- grepl("DRB[345]", molecular_locus)
  keep <- !is.na(allele_clean) & !(allele_clean == "XX" & is_drb345_locus)

  row_idx          <- row_idx[keep]
  molecular_locus  <- molecular_locus[keep]
  molecular_cell   <- molecular_cell[keep]
  serologic_name_c <- serologic_name_col[col_idx[keep]]
  allele_clean     <- allele_clean[keep]
  DRB345           <- DRB345[keep]

  # --- Build the per-cell final_type string --------------------------------
  # Molecular: "<locus>*<allele>"; Serologic: "<serologic_name><allele>".
  final_type <- ifelse(
    molecular_cell,
    paste0(molecular_locus, "*", allele_clean),
    paste0(serologic_name_c, allele_clean)
  )

  # --- Two-level collapse: (row, locus, DRB345) with "+", then row with "^".
  # First-appearance order within each row is preserved by grouping on
  # match() against unique(), mirroring dplyr's .by behaviour.
  key1         <- paste(row_idx, molecular_locus, as.integer(DRB345), sep = "\x01")
  unique_keys  <- unique(key1)
  grp1         <- match(key1, unique_keys)
  # split() groups in ascending grp1 order, which by construction is the
  # first-appearance order of each (row, locus, DRB345) combination.
  final_type_2 <- vapply(
    split(final_type, grp1),
    paste, character(1), collapse = "+"
  )
  row_per_group <- row_idx[match(unique_keys, key1)]

  # Level 2: collapse per row with "^". split() on a numeric vector orders
  # groups by ascending row number, which matches how v1's summarise(.by =
  # row_for_function) produced its output.
  row_groups <- split(final_type_2, row_per_group)
  out <- vapply(row_groups, paste, character(1), collapse = "^")
  # Drop names so the result is a plain character vector, matching v1's
  # pull() output.
  unname(out)
}

globalVariables(c(
  ".", "truncated_names", "lower_names", "locus_from_name", "DRB_locus",
  "row_for_function", "molecular_locus", "molecular", "serologic_name",
  "final_type", "DRB345", "final_type_2", "GL_string", "DRB_locus_raw"
))
