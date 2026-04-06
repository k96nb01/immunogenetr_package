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
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr select
#' @importFrom dplyr %>%
#' @importFrom stringr str_extract
#' @importFrom tidyr replace_na
#' @importFrom dplyr na_if
#' @importFrom tidyr separate_wider_delim
#' @importFrom tidyr unite


HLA_truncate <- function(data, fields = 2, keep_suffix = TRUE, keep_G_P_group = FALSE, remove_duplicates = FALSE) {
  # Validate inputs
  check_gl_string(data, "data")
  check_fields(fields)
  check_logical_flag(keep_suffix, "keep_suffix")
  check_logical_flag(keep_G_P_group, "keep_G_P_group")
  check_logical_flag(remove_duplicates, "remove_duplicates")

  # Expand the GL string
  alleles <- GLstring_expand_longer(data) %>%
    # Extract any WHO-recognized suffixes
    mutate(suffix = replace_na(str_extract(value, "(?<=[:digit:])[LSCAQNlscaqn]$"), "")) %>%
    # Extract any P or G group designation
    mutate(GP = replace_na(str_extract(value, "(?<=[:digit:])[PGpg]$"), "")) %>%
    # Separate HLA prefix if available
    separate_wider_delim(value, delim = "-", names = c("prefix", "rest"), too_few = "align_end") %>%
    separate_wider_delim(rest, delim = "*", names = c("gene", "molecular_type"), too_few = "align_start") %>%
    # Separate molecular fields
    separate_wider_delim(molecular_type, delim = ":", names = c("one", "two", "three", "four"), too_few = "align_start") %>%
    # Keep only numbers in each field, in case there were non-standard suffixes.
    mutate(across(one:four, ~ str_extract(., "[:digit:]+")))

  # Determine which field columns to keep and which to drop based on requested fields.
  all_field_cols <- c("one", "two", "three", "four")
  keep_cols <- all_field_cols[seq_len(fields)]
  drop_cols <- setdiff(all_field_cols, keep_cols)

  # Drop the unneeded field columns.
  if (length(drop_cols) > 0) {
    alleles <- alleles %>% select(-all_of(drop_cols))
  }

  # Reunite the prefix and gene name (e.g. "HLA" + "A" -> "HLA-A").
  truncated <- alleles %>%
    unite(gene, prefix:gene, sep = "-", na.rm = TRUE)

  # Reunite the retained field columns into the allele code.
  if (fields == 1) {
    # Single field: unite directly with the gene using "*" separator.
    truncated <- truncated %>%
      unite(gene, gene, one, sep = "*", na.rm = TRUE)
  } else {
    # Multiple fields: join fields with ":", then unite with gene using "*".
    truncated <- truncated %>%
      unite(code, all_of(keep_cols), sep = ":", na.rm = TRUE) %>%
      mutate(code = na_if(code, "")) %>%
      unite(gene, gene, code, sep = "*", na.rm = TRUE)
  }

  # Retain or drop suffix and P/G group designation.
  if (keep_suffix) {
    truncated <- truncated %>% unite(gene, gene, suffix, sep = "", na.rm = TRUE)
  } else {
    truncated <- truncated %>% select(-suffix)
  }
  if (keep_G_P_group) {
    truncated <- truncated %>% unite(gene, gene, GP, sep = "", na.rm = TRUE)
  } else {
    truncated <- truncated %>% select(-GP)
  }

  # Combine everything back to a GL string.
  truncated %>%
    rename(value = gene) %>%
    ambiguity_table_to_GLstring(., remove_duplicates = remove_duplicates)
}


globalVariables(c(
  "rest", "molecular_type", "one", "four", "three",
  "two", "gene", "prefix", "code", "suffix", "GP"
))
