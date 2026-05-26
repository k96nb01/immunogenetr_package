#' @title HLA_truncate
#'
#' @description This function truncates HLA typing values in molecular nomenclature
#' (for example from 4 fields to 2 fields). The truncation is based on the number
#' of fields specified and optionally retains any WHO-recognized suffixes
#' (L, S, C, A, Q, or N) or G and P group designations (G or P). This function
#' will work on individual alleles (e.g. "HLA-A*02:01:01:01") or on all alleles
#' in a GL string (e.g. "HLA-A*02:01:01:01+HLA-A*68:01:01^HLA-DRB1*01:01:01+HLA-DRB1*03:01:01").
#'
#' Note: depending on arguments used, this function can output HLA alleles that do not
#' exist in the IPD-IMGT/HLA database. For example, truncating the allele "DRB4*01:03:01:02N"
#' to 2 fields would result in "DRB4*01:03N," which does not exist in the IPD-IMGT/HLA database.
#' Users should take care in setting the parameters for this function.
#'
#' @param data A string containing an HLA allele or a GL string.
#' @param fields An integer specifying the number of fields to retain in the
#' truncated values. Default is 2.
#' @param keep_suffix A logical value indicating whether to retain any
#' WHO-recognized suffixes. Default is TRUE.
#' @param keep_G_P_group A logical value indicating whether to retain any
#' G or P group designations. Default is FALSE.
#' @param remove_duplicates A logical value indicating whether to remove duplicated
#' values from a GL string after truncation. Default is FALSE.
#'
#' @return A string with the HLA typing truncated according to
#' the specified number of fields and optional suffix retention.
#'
#' @examples
#'
#' # The Haplotype_frequencies dataset contains a table with HLA typing spread across multiple columns:
#' print(Haplotype_frequencies)
#'
#' # The `HLA_truncate` function can be used to truncate the typing results to 2 fields:
#' library(dplyr)
#' Haplotype_frequencies %>% mutate(
#'   across(
#'     "HLA-A":"HLA-DPB1",
#'     ~ HLA_truncate(
#'       .,
#'       fields = 2,
#'       keep_suffix = TRUE,
#'       keep_G_P_group = FALSE
#'     )
#'   )
#' )
#'
#' @export
#'
#' @importFrom stringi stri_extract_first_regex stri_split_fixed

HLA_truncate <- function(data, fields = 2, keep_suffix = TRUE, keep_G_P_group = FALSE, remove_duplicates = FALSE) {
  # Validate inputs — identical error shape to v1.
  check_gl_string(data, "data")
  check_fields(fields)
  check_logical_flag(keep_suffix, "keep_suffix")
  check_logical_flag(keep_G_P_group, "keep_G_P_group")
  check_logical_flag(remove_duplicates, "remove_duplicates")

  # Define the per-allele truncator as a local closure so it is always
  # in lexical scope — regardless of whether the file is source()'d
  # into a private env or installed as part of the package namespace.
  # Per-call closure creation is O(1) and negligible.
  truncate_allele_vec <- function(alleles, fields, keep_suffix, keep_G_P_group) {
    n <- length(alleles)
    if (n == 0L) return(character(0))

    # NAs pass through untouched — matches v1's behaviour inside the
    # tidy pipeline (separate_wider_delim leaves NA as NA, unite with
    # na.rm = TRUE drops it, ambiguity_table_to_GLstring then stays NA).
    out   <- character(n)
    is_na <- is.na(alleles)
    out[is_na] <- NA_character_

    idx <- which(!is_na)
    if (length(idx) == 0L) return(out)
    vals <- alleles[idx]

    # --- Strip "HLA-" prefix if present ----------------------------------
    has_hla <- startsWith(vals, "HLA-")
    rest <- vals
    rest[has_hla] <- substr(vals[has_hla], 5L, nchar(vals[has_hla]))

    # --- Split locus from molecular portion at "*" -----------------------
    # regexpr with fixed = TRUE is a single C-level scan per cell; no
    # regex compilation overhead.
    star_pos <- regexpr("*", rest, fixed = TRUE)
    has_star <- star_pos != -1L
    gene <- rest
    gene[has_star] <- substr(rest[has_star], 1L, star_pos[has_star] - 1L)
    mol_full <- character(length(rest))
    mol_full[has_star] <- substr(
      rest[has_star],
      star_pos[has_star] + 1L,
      nchar(rest[has_star])
    )
    # Cells without a "*" (e.g. bare serologic "27") have mol_full = "".

    # --- Extract WHO suffix (L/S/C/A/Q/N) if it follows a digit at end ---
    # v1 used "(?<=[:digit:])[LSCAQNlscaqn]$" with str_extract — a
    # look-behind regex. We use a plain two-char match and subset out
    # the letter; same semantics, no look-behind overhead.
    suffix_m   <- regexpr("[[:digit:]][LSCAQNlscaqn]$", mol_full, perl = TRUE)
    has_suffix <- suffix_m != -1L
    suffix <- rep("", length(mol_full))
    suffix[has_suffix] <- substr(
      mol_full[has_suffix],
      suffix_m[has_suffix] + 1L,
      suffix_m[has_suffix] + 1L
    )
    # Remove the matched suffix letter from mol_full. The digit before
    # the suffix stays put for field splitting below.
    mol_no_suffix <- mol_full
    mol_no_suffix[has_suffix] <- substr(
      mol_full[has_suffix], 1L, suffix_m[has_suffix]
    )

    # --- Extract G or P group marker if it follows a digit at end -------
    gp_m   <- regexpr("[[:digit:]][PGpg]$", mol_no_suffix, perl = TRUE)
    has_gp <- gp_m != -1L
    gp <- rep("", length(mol_no_suffix))
    gp[has_gp] <- substr(
      mol_no_suffix[has_gp],
      gp_m[has_gp] + 1L,
      gp_m[has_gp] + 1L
    )
    mol_clean <- mol_no_suffix
    mol_clean[has_gp] <- substr(
      mol_no_suffix[has_gp], 1L, gp_m[has_gp]
    )

    # --- Split into fields by ":", keep first `fields`, dig-extract, collapse
    #
    # Done as a FLAT pass, not a per-allele vapply — the per-allele vapply
    # approach called stri_extract_first_regex thousands of times on tiny
    # inputs, and that C-call overhead dominated. Here every stringi /
    # regex call operates on one long vector of all fields at once.
    split_list <- stringi::stri_split_fixed(mol_clean, ":")
    n_per_all  <- lengths(split_list)                        # fields per allele
    flat_f     <- unlist(split_list, use.names = FALSE)       # all fields flat
    allele_id  <- rep.int(seq_along(split_list), n_per_all)   # which allele each field belongs to
    field_pos  <- sequence(n_per_all)                          # 1..k per allele

    # Extract the leading digit run in ONE C call over the whole flat vector
    # (instead of N vapply calls on tiny per-allele vectors).
    flat_dig   <- stringi::stri_extract_first_regex(flat_f, "[[:digit:]]+")

    # Keep only: within each allele, the first `fields` fields that had a
    # digit match. NAs correspond to fields with no digit run, same as v1
    # dropping them via na.rm = TRUE in unite().
    keep_mask  <- field_pos <= fields & !is.na(flat_dig)
    kept_dig   <- flat_dig[keep_mask]
    kept_aid   <- allele_id[keep_mask]

    # Collapse kept fields with ":" per allele. factor(..., levels = seq_along)
    # guarantees a slot for every allele (including ones whose fields were
    # all dropped — those get "").
    truncated_codes <- character(length(split_list))
    if (length(kept_dig) > 0L) {
      grouped <- split(
        kept_dig,
        factor(kept_aid, levels = seq_along(split_list))
      )
      truncated_codes <- vapply(grouped, paste, character(1), collapse = ":")
    }
    names(truncated_codes) <- NULL

    # --- Reassemble the allele string -----------------------------------
    # Layout (per row): [HLA-] gene [*code] [suffix] [GP]
    # Bare serologic inputs and alleles without any code come out with
    # just [prefix] gene, matching v1.
    prefix <- ifelse(has_hla, "HLA-", "")
    star   <- ifelse(nzchar(truncated_codes), "*", "")
    suffix_part <- if (keep_suffix)     suffix else ""
    gp_part     <- if (keep_G_P_group)  gp     else ""
    rebuilt <- paste0(prefix, gene, star, truncated_codes, suffix_part, gp_part)

    out[idx] <- rebuilt
    out
  }

  # -------------------------------------------------------------------------
  # Iteration 7 rewrite: the v1 pipeline used separate_wider_delim + unite
  # round-trips to slice an allele into (prefix, gene, fields, suffix, GP)
  # and put it back together. Profiling showed the four unite() calls were
  # 30% of v1's self time; separate_wider_delim was another ~15%. Both are
  # generic, tidyr-dispatched column operations on what is really a simple
  # per-allele string transform.
  #
  # v2 calls GLstring_expand_longer once (now fast post-iter-6), applies a
  # fully-vectorised allele truncator to the `value` column with stringi +
  # base regex, and calls ambiguity_table_to_GLstring once (now fast
  # post-iter-7) to reassemble. The intermediate tibble never grows extra
  # columns.
  # -------------------------------------------------------------------------

  # Expand the GL string into the ambiguity-table layout. This is cheap
  # after iter-6: a single stri_split cascade, no tidyr unchop.
  table <- GLstring_expand_longer(data)

  # Truncate every allele in the value column in one vectorised pass.
  table$value <- truncate_allele_vec(
    table$value,
    fields = fields,
    keep_suffix = keep_suffix,
    keep_G_P_group = keep_G_P_group
  )

  # Reassemble the GL string. ambiguity_table_to_GLstring is now the v2
  # sort-and-paste implementation from earlier in this iteration.
  ambiguity_table_to_GLstring(table, remove_duplicates = remove_duplicates)
}

globalVariables(c(
  "rest", "molecular_type", "one", "four", "three",
  "two", "gene", "prefix", "code", "suffix", "GP"
))
