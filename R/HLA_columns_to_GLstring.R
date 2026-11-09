#' @title HLA_columns_to_GLstring
#'
#' @description A function to take HLA typing data spread across different columns,
#' as is often found in wild-caught data, and transform it to a GL String. If column names
#' have anything besides the locus name and a number (e.g. "mA1Cd" instead of just "A1"),
#' the function will have trouble determining the locus from the column name. The `prefix_to_remove`
#' and `suffix_to_remove` arguments can be used to clean up the column names. See the example for
#' how these arguments are used.
#'
#' @param data A data frame with each row including an HLA typing result, with
#' individual columns containing a single allele or, when requested, a
#' `/`-delimited allele-ambiguity list (see `take_first_allele`).
#' @param HLA_typing_columns A list of columns containing the HLA alleles. Tidyselect is supported.
#' @param prefix_to_remove An optional string of characters to remove from the
#' locus names. The goal is to get the column names to the locus and a number. For example,
#' columns named "mDRB11Cd" and "mDRB12Cd" should use the `prefix_to_remove` value of "m".
#' @param suffix_to_remove An optional string of characters to remove from the
#' locus names. Using the example above, the `suffix_to_remove` value will be "Cd".
#' @param nomenclature An optional declaration of the output nomenclature, applied
#' per locus. By default (`NULL`) each cell is auto-detected: a value is molecular
#' if it contains a colon, starts with a zero, contains a non-leading asterisk, or
#' sits in a DQA1/DPA1/DPB1 column (a bare leading asterisk such as `"*17"` is
#' treated as serologic). Supply `"mol"` or `"ser"` to force every selected locus
#' to that nomenclature, or a named vector to set it per locus, e.g.
#' `c("HLA-Cw" = "ser", "HLA-DRB1" = "mol")`. Keys may be given in either the
#' molecular or serologic spelling of a locus (`"HLA-C"` and `"HLA-Cw"` are
#' equivalent). Relabeling is structural only: `"ser"` strips any asterisk and
#' uses the serologic locus name; `"mol"` uses the molecular locus name. No
#' cross-nomenclature allele translation is performed.
#' @param take_first_allele A logical value or `"keep"`. If TRUE (the
#' default), a cell containing GL String delimiters (`"^"`, `"|"`, `"+"`,
#' `"~"`, `"/"` or `"?"`) is silently reduced to its first allele. If FALSE,
#' such cells raise an error. If `"keep"`, `/`-delimited allele ambiguity is
#' retained and every allele is cleaned and prefixed independently; cells
#' containing any other GL String delimiter still raise an error.
#'
#' @return A list of GL Strings in the order of the original data frame.
#'
#' @examples
#' # The HLA_typing_LIS dataset contains a table as might be found in a clinical laboratory
#' # information system:
#' print(HLA_typing_LIS)
#'
#' # The `HLA_columns_to_GLstring` function can be used to coerce typing spread across
#' # multiple columns into a GL String:
#' library(dplyr)
#' HLA_typing_LIS |>
#'   mutate(
#'     GL_string = HLA_columns_to_GLstring(
#'       pick(everything()),
#'       HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
#'       prefix_to_remove = "m",
#'       suffix_to_remove = "Cd.recipient"
#'     ),
#'     .after = patient
#'   ) |>
#'   select(patient, GL_string)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom dplyr ungroup
#' @importFrom cli cli_abort
#' @importFrom stringi stri_startswith_fixed stri_endswith_fixed

HLA_columns_to_GLstring <- function(data, HLA_typing_columns, prefix_to_remove = "", suffix_to_remove = "", nomenclature = NULL, take_first_allele = TRUE) {
  # Validate the data frame input up-front.
  check_data_frame(data, "data")

  keep_ambiguity <- is.character(take_first_allele) &&
    length(take_first_allele) == 1L &&
    !is.na(take_first_allele) &&
    take_first_allele == "keep"
  if (!keep_ambiguity) {
    check_logical_flag(take_first_allele, "take_first_allele")
  }

  # Resolve the tidyselect argument to a character vector of column names.
  col2mod <- names(select(ungroup(data), {{ HLA_typing_columns }}))

  n_rows <- nrow(data)
  n_cols <- length(col2mod)
  if (n_cols == 0L) {
    cli_abort("{.arg HLA_typing_columns} did not select any columns.")
  }

  # -------------------------------------------------------------------------
  # Iteration 6 rewrite: build the GL Strings with a single vectorised pass
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
    "HLA-DPB1" = "HLA-DPB"
  )
  serologic_name_col <- serologic_map[locus_from_name]

  # Canonical (nomenclature-independent) locus identity. Collapses serologic
  # locus spellings onto their molecular locus so the two are treated as ONE
  # locus: a "Cw" column and a "C" column - or serologic and molecular values
  # in the same column - group together (never split across "^"), and molecular
  # output always uses the molecular name (Cw -> C). Bw is left as-is (it is an
  # epitope, not a molecular locus). (issue #40 §5.4)
  canonical_locus_map <- c(
    "HLA-Cw" = "HLA-C",
    "HLA-DR" = "HLA-DRB1",
    "HLA-DQ" = "HLA-DQB1"
  )
  to_canonical <- function(x) {
    hit <- unname(canonical_locus_map[x])
    ifelse(is.na(hit), x, hit)
  }

  # Resolve the optional `nomenclature` override into a per-column setting of
  # "mol" / "ser" / NA (= auto-detect). Accepts a scalar (one value for every
  # selected locus) or a named vector keyed by locus in EITHER nomenclature
  # spelling (normalized to the canonical locus before matching). (issue #40 §5.3)
  nomen_col <- rep(NA_character_, n_cols)
  if (!is.null(nomenclature)) {
    if (is.null(names(nomenclature))) {
      # Scalar form: one value applied to every selected locus.
      nomen_col[] <- match.arg(nomenclature, c("mol", "ser"))
    } else {
      # Named-vector form: validate values, normalize keys, map to columns.
      bad_vals <- setdiff(unique(unname(nomenclature)), c("mol", "ser"))
      if (length(bad_vals) > 0L) {
        cli_abort("{.arg nomenclature} values must be {.val mol} or {.val ser}.")
      }
      keys_canon <- to_canonical(names(nomenclature))
      nomen_col  <- unname(nomenclature[match(to_canonical(locus_from_name), keys_canon)])
    }
  }

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

  # In "keep" mode, expand slash ambiguity before every per-cell decision so
  # nomenclature detection, prefix repair, and DRB3/4/5 inference run on each
  # alternative independently. `cell_idx` records the original input cell for
  # reassembly after those transformations.
  cell_idx <- seq_along(raw)
  if (keep_ambiguity) {
    raw <- as.character(raw)
    other_gl_input <- !is.na(raw) & grepl("[\\^|+~?]", raw)
    if (any(other_gl_input)) {
      cli_abort("{sum(other_gl_input)} value{?s} passed to {.fn HLA_columns_to_GLstring} contain{?s/} GL String delimiters other than {.val /} (e.g. {.val {raw[other_gl_input][1]}}). Only allele ambiguity separated by {.val /} can be retained when {.arg take_first_allele} is {.val keep}.")
    }

    ambiguity_parts <- lapply(raw, function(value) {
      if (is.na(value) || !nzchar(value)) {
        value
      } else {
        if (startsWith(value, "/") || endsWith(value, "/") || grepl("//", value, fixed = TRUE)) {
          cli_abort("Allele-ambiguity value {.val {value}} contains an empty alternative. Every allele separated by {.val /} must be non-empty.")
        }
        strsplit(value, "/", fixed = TRUE)[[1]]
      }
    })
    cell_idx <- rep.int(cell_idx, lengths(ambiguity_parts))
    raw <- unlist(ambiguity_parts, use.names = FALSE)
    row_idx <- row_idx[cell_idx]
    col_idx <- col_idx[cell_idx]
  }

  # --- Per-cell transformations --------------------------------------------

  # DEFAULT (auto-detect) classification, decided from the RAW cell value. A
  # cell is molecular if any of these signals are present:
  #
  #   1. contains ':'              — multi-field molecular, e.g. A*01:01 or 01:01
  #   2. starts with '0'          — leading-zero low-res molecular, e.g. 01
  #   3. contains a NON-leading '*' — "<locus>*<fields>" form, e.g. A*01, DRB3*01.
  #                                 Catches low-res molecular like A*01 / B*07 that
  #                                 lack a colon and don't start with 0.
  #   4. per-column override       — DQA1/DPA1/DPB1 columns are always molecular.
  #
  # A BARE LEADING '*' (e.g. "*17") is deliberately NOT a molecular signal: a
  # C-locus allele with no serologic equivalent was historically recorded as
  # "*17" in a Cw column, and is rendered serologically by default (matching
  # pre-1.3.0 behavior). Requiring the '*' to be non-leading keeps the low-res
  # molecular fix while restoring that. (issue #40 §3a)
  has_colon        <- !is.na(raw) & grepl(":", raw, fixed = TRUE)
  has_leading_zero <- !is.na(raw) & startsWith(raw, "0")
  has_inner_star   <- !is.na(raw) & grepl("*", raw, fixed = TRUE) & !startsWith(raw, "*")
  auto_molecular   <- has_colon | has_leading_zero | has_inner_star | is_mol_col[col_idx]

  # Apply any caller-declared `nomenclature` override (per column). Bw is an
  # epitope with no molecular form, so it is never molecular regardless of the
  # override or the auto-detect signals. (issue #40 §5.3, §5.5)
  nomen_cell <- nomen_col[col_idx]
  force_ser  <- !is.na(nomen_cell) & nomen_cell == "ser"
  force_mol  <- !is.na(nomen_cell) & nomen_cell == "mol"
  is_bw      <- locus_from_name[col_idx] == "HLA-Bw"
  molecular_cell <- auto_molecular
  molecular_cell[force_ser] <- FALSE
  molecular_cell[force_mol] <- TRUE
  molecular_cell[is_bw]     <- FALSE

  # Clean each allele via HLA_validate, then strip its "HLA-"/locus prefix so
  # the output re-applies locus names consistently.
  validated <- HLA_validate(
    raw,
    take_first_allele = if (keep_ambiguity) TRUE else take_first_allele
  )

  # Capture an explicit locus on each ambiguity member before removing it.
  # Molecular names take everything before "*" (e.g. DRB4); serologic names
  # take the leading letters (e.g. Cw or DR). Bare field values have no hint.
  explicit_locus <- rep(NA_character_, length(validated))
  if (keep_ambiguity) {
    explicit_locus <- vapply(validated, function(value) {
      if (is.na(value)) {
        return(NA_character_)
      }
      value <- sub("^HLA-", "", value, ignore.case = TRUE)
      if (grepl("*", value, fixed = TRUE)) {
        return(sub("\\*.*$", "", value))
      }
      hit <- regexpr("^[[:alpha:]]+", value)
      if (hit == -1L) NA_character_ else regmatches(value, hit)
    }, character(1), USE.NAMES = FALSE)
  }
  allele_clean <- HLA_prefix_remove(validated)

  # Allele-derived DRB3/4/5 hint, preferred over the column-name locus when
  # present: (1) "DRB[345]*" anywhere (e.g. "HLA-DRB3*01:01") -> the digit after
  # "DRB"; (2) a leading "[345]*" -> that digit. (1) wins over (2).
  drb_num_A <- rep("", length(validated))
  mA <- regexpr("DRB[345]", validated, perl = TRUE, ignore.case = TRUE)
  hasA <- mA != -1L & !is.na(mA)
  drb_num_A[hasA] <- substr(validated[hasA], mA[hasA] + 3L, mA[hasA] + 3L)
  drb_num_B <- rep("", length(validated))
  hasB <- !is.na(validated) & grepl("^[345]\\*", validated)
  drb_num_B[hasB] <- substr(validated[hasB], 1L, 1L)
  drb_num <- drb_num_A
  use_B <- drb_num == "" & drb_num_B != ""
  drb_num[use_B] <- drb_num_B[use_B]
  drb_locus_raw <- rep(NA_character_, length(validated))
  drb_locus_raw[drb_num != ""] <- paste0("HLA-DRB", drb_num[drb_num != ""])

  # Column-derived locus, refined by the allele-derived DRB3/4/5 hint, then
  # mapped to the canonical (nomenclature-independent) locus identity. Grouping
  # and the molecular locus label both use the canonical name, so a locus is
  # never split across "^" and molecular output always uses the molecular name.
  molecular_locus <- ifelse(is.na(drb_locus_raw), locus_from_name[col_idx], drb_locus_raw)
  canonical_locus <- to_canonical(molecular_locus)

  # DR51/52/53, when a DR column is FORCED molecular, are broad specificities
  # that map to the DRB5/DRB3/DRB4 loci with an unknown ("XX") allele (the
  # serologic number carries no allele information; DR52 != DRB3*52). Every
  # other DR value maps to DRB1 and keeps its allele. Restricted to serologic
  # "DR" columns so genuine DRB1 columns are untouched. (issue #40 §5.6)
  if (keep_ambiguity) {
    ambiguity_member <- stats::ave(cell_idx, cell_idx, FUN = length) > 1L
    generic_dr_legacy <- !ambiguity_member &
      locus_from_name[col_idx] == "HLA-DR"
    retained_dr_hint <- ambiguity_member &
      startsWith(locus_from_name[col_idx], "HLA-DR") &
      (is.na(explicit_locus) | toupper(explicit_locus) == "DR")
    dr_mol <- force_mol & (generic_dr_legacy | retained_dr_hint)
  } else {
    dr_mol <- force_mol & (locus_from_name[col_idx] == "HLA-DR")
  }
  allele_clean_for_validation <- allele_clean
  if (any(dr_mol)) {
    is51 <- dr_mol & !is.na(allele_clean) & allele_clean == "51"
    is52 <- dr_mol & !is.na(allele_clean) & allele_clean == "52"
    is53 <- dr_mol & !is.na(allele_clean) & allele_clean == "53"
    canonical_locus[is51] <- "HLA-DRB5"; allele_clean[is51] <- "XX"
    canonical_locus[is52] <- "HLA-DRB3"; allele_clean[is52] <- "XX"
    canonical_locus[is53] <- "HLA-DRB4"; allele_clean[is53] <- "XX"
  }

  # Slash ambiguity represents alternatives at one allele position, so every
  # member must resolve to the same canonical locus. Run this after forced
  # DR51/52/53 mapping because that mapping can change a member's locus.
  # Mixed nomenclature is allowed (e.g. Cw7/C*17:01), but mixed loci are not.
  if (keep_ambiguity) {
    explicit_map <- c(
      "A" = "HLA-A", "B" = "HLA-B", "BW" = "HLA-Bw",
      "C" = "HLA-C", "CW" = "HLA-C",
      "DR" = "HLA-DRB1", "DRB1" = "HLA-DRB1",
      "DRB3" = "HLA-DRB3", "DRB4" = "HLA-DRB4", "DRB5" = "HLA-DRB5",
      "3" = "HLA-DRB3", "4" = "HLA-DRB4", "5" = "HLA-DRB5",
      "DQ" = "HLA-DQB1", "DQB1" = "HLA-DQB1",
      "DQA" = "HLA-DQA1", "DQA1" = "HLA-DQA1",
      "DPA" = "HLA-DPA1", "DPA1" = "HLA-DPA1",
      "DPB" = "HLA-DPB1", "DPB1" = "HLA-DPB1"
    )
    explicit_canonical <- unname(explicit_map[toupper(explicit_locus)])
    unknown_explicit <- !is.na(explicit_locus) & is.na(explicit_canonical)
    if (any(unknown_explicit)) {
      bad_member <- which(unknown_explicit)[1]
      bad_cell <- cell_idx[bad_member]
      cli_abort("Allele-ambiguity value {.val {as.vector(allele_mat)[bad_cell]}} contains the unrecognized HLA locus {.val {explicit_locus[bad_member]}}. Every explicit locus in a retained ambiguity list must be recognized.")
    }
    validation_locus <- canonical_locus
    has_explicit <- !is.na(explicit_canonical)
    validation_locus[has_explicit] <- explicit_canonical[has_explicit]
    dr_mol_hint <- dr_mol & (is.na(explicit_canonical) | toupper(explicit_locus) == "DR")
    validation_locus[dr_mol_hint] <- canonical_locus[dr_mol_hint]

    # DR51/52/53 imply DRB5/3/4 even when their output stays serologic. Apply
    # the hint throughout the DR family, including generic DRB345 and dedicated
    # secondary-DR columns, because wild-caught data can carry the broad
    # specificity alongside its molecular form in any of those columns.
    dr_hint <- startsWith(locus_from_name[col_idx], "HLA-DR")
    broad_hint <- dr_hint & (is.na(explicit_canonical) | toupper(explicit_locus) == "DR")
    validation_locus[broad_hint & !is.na(allele_clean_for_validation) & allele_clean_for_validation == "51"] <- "HLA-DRB5"
    validation_locus[broad_hint & !is.na(allele_clean_for_validation) & allele_clean_for_validation == "52"] <- "HLA-DRB3"
    validation_locus[broad_hint & !is.na(allele_clean_for_validation) & allele_clean_for_validation == "53"] <- "HLA-DRB4"

    loci_per_cell <- split(validation_locus, cell_idx)
    mixed_locus <- vapply(loci_per_cell, function(x) length(unique(x)) > 1L, logical(1))
    if (any(mixed_locus)) {
      bad_cell <- as.integer(names(mixed_locus)[which(mixed_locus)[1]])
      cli_abort("Allele-ambiguity value {.val {as.vector(allele_mat)[bad_cell]}} contains alternatives from different HLA loci. All alleles separated by {.val /} must belong to the same locus.")
    }

    # Use the resolved ambiguity locus for downstream grouping. This keeps a
    # broad/molecular pair such as DR52/DRB3*01:01 in the same `+`-joined DRB3
    # group as another DRB3 allele instead of splitting it across `^`.
    canonical_locus[ambiguity_member] <- validation_locus[ambiguity_member]
  }

  # DR51/52/53 SEROLOGIC grouping flag (default rendering): keep serologic DR5x
  # entries in their own group, separate from the other DR antigens, matching
  # historical behavior. (Forced-molecular DR5x are already split by canonical
  # locus above, so this only affects serologic output.)
  DRB345 <- !is.na(allele_clean) &
            startsWith(allele_clean, "5") &
            locus_from_name[col_idx] == "HLA-DR"

  # --- XX logic (group by row x canonical_locus) ---------------------------
  # If every allele in a (row, locus) group is NA, emit one "XX" PLACEHOLDER so
  # the locus survives the NA filter; then drop NAs and drop the placeholder XX
  # for any DRB[345] locus (which is optional). A forced DR5x "XX" (a real value
  # set above) is not a placeholder and is therefore kept.
  grp_key        <- paste(row_idx, canonical_locus, sep = "\x01")
  grp_ix         <- match(grp_key, unique(grp_key))
  n_per_grp      <- tabulate(grp_ix)
  n_na_per_grp   <- tabulate(grp_ix[is.na(allele_clean)], nbins = length(n_per_grp))
  all_na_grp     <- n_per_grp == n_na_per_grp
  placeholder_xx <- is.na(allele_clean) & all_na_grp[grp_ix]
  allele_clean[placeholder_xx] <- "XX"

  is_drb345_locus <- grepl("DRB[345]", canonical_locus)
  keep <- !is.na(allele_clean) & !(placeholder_xx & is_drb345_locus)

  row_idx          <- row_idx[keep]
  cell_idx         <- cell_idx[keep]
  canonical_locus  <- canonical_locus[keep]
  molecular_cell   <- molecular_cell[keep]
  serologic_name_c <- serologic_name_col[col_idx[keep]]
  allele_clean     <- allele_clean[keep]
  DRB345           <- DRB345[keep]

  # --- Build the per-cell final_type string --------------------------------
  # Molecular: "<canonical-locus>*<allele>"; serologic: "<serologic-name><allele>".
  # Prefix every member of a retained ambiguity list rather than only its head.
  final_type <- ifelse(
    molecular_cell,
    paste0(canonical_locus, "*", allele_clean),
    paste0(serologic_name_c, allele_clean)
  )

  # Reassemble alternatives into their original cell after every member has
  # received its own locus and nomenclature treatment.
  if (keep_ambiguity) {
    unique_cells <- unique(cell_idx)
    cell_group <- match(cell_idx, unique_cells)
    final_type <- vapply(split(final_type, cell_group), paste, character(1), collapse = "/")
    first_member <- match(unique_cells, cell_idx)
    row_idx <- row_idx[first_member]
    canonical_locus <- canonical_locus[first_member]
    DRB345 <- DRB345[first_member]
    cell_sizes <- tabulate(cell_group, nbins = length(unique_cells))
    resolved_secondary_dr <- cell_sizes > 1L & grepl("DRB[345]", canonical_locus)
    DRB345[resolved_secondary_dr] <- FALSE
  }

  # --- Two-level collapse: (row, canonical_locus, DRB345) with "+", then row
  # with "^". First-appearance order within each row is preserved by grouping
  # on match() against unique(), mirroring dplyr's .by behaviour.
  key1         <- paste(row_idx, canonical_locus, as.integer(DRB345), sep = "\x01")
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
  "truncated_names", "lower_names", "locus_from_name", "DRB_locus",
  "row_for_function", "molecular_locus", "molecular", "serologic_name",
  "final_type", "DRB345", "final_type_2", "GL_string", "DRB_locus_raw"
))
