#' @title HLA_truncate
#'
#' @description This function truncates HLA typing values in molecular nomenclature
#' (for example from 4 fields to 2 fields). The truncation is based on the number
#' of fields specified and optionally retains any WHO-recognized suffixes
#' (L, S, C, A, Q, or N) or G and P group designations (G or P). This function
#' will work on individual alleles (e.g. "HLA-A*02:01:01:01") or on all alleles
#' in a GL string (e.g. "HLA-A*02:01:01:01+HLA-A*68:01:01^HLA-DRB1*01:01:01+HLA-DRB1*03:01:01").
#'
#'
#' @param data A string containing an HLA allele or a GL string.
#' @param fields An integer specifying the number of fields to retain in the
#' truncated values. Default is 2.
#' @param keep_suffix A logical value indicating whether to retain any
#' WHO-recognized suffixes. Default is TRUE.
#' @param keep_G_P_group A logical value indicating whether to retain any
#' G or P group designations. Default is FALSE.
#'
#' @return A string with the HLA typing truncated according to
#' the specified number of fields and optional suffix retention.
#'
#' @examples
#'
#' file <- Haplotype_frequencies
#' file$`HLA-A` <- HLA_prefix_add(file$`HLA-A`, "HLA-")
#' file$`HLA-A` <- sapply(file$`HLA-A`, HLA_truncate)
#' View(file$`HLA-A`)
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


HLA_truncate <- function(data, fields = 2, keep_suffix = TRUE, keep_G_P_group = FALSE) {
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

  # Delete fields for truncating and reunite the alleles
  if (fields == 1) {
    trunctated <- alleles %>%
      select(-four, -three, -two) %>%
      unite(gene, prefix:gene, sep = "-", na.rm = TRUE) %>%
      unite(gene, gene, one, sep = "*", na.rm = TRUE)
  } else if (fields == 2) {
    trunctated <- alleles %>%
      select(-four, -three) %>%
      unite(gene, prefix:gene, sep = "-", na.rm = TRUE) %>%
      unite(code, one:two, sep = ":", na.rm = TRUE) %>%
      mutate(code = na_if(code, "")) %>%
      unite(gene, gene, code, sep = "*", na.rm = TRUE)
  } else if (fields == 3) {
    trunctated <- alleles %>%
      select(-four) %>%
      unite(gene, prefix:gene, sep = "-", na.rm = TRUE) %>%
      unite(code, one:three, sep = ":", na.rm = TRUE) %>%
      mutate(code = na_if(code, "")) %>%
      unite(gene, gene, code, sep = "*", na.rm = TRUE)
  } else {
    trunctated <- alleles %>%
      unite(gene, prefix:gene, sep = "-", na.rm = TRUE) %>%
      unite(code, one:four, sep = ":", na.rm = TRUE) %>%
      mutate(code = na_if(code, "")) %>%
      unite(gene, gene, code, sep = "*", na.rm = TRUE)
  }

  # Retain suffix if desired
  if (keep_suffix) {
    with_suffix <- trunctated %>% unite(gene, gene, suffix, sep = "", na.rm = TRUE)
  } else {
    with_suffix <- trunctated %>% select(-suffix)
  }
  # Retain P/G group designation if desired
  if (keep_G_P_group) {
    with_g_p <- with_suffix %>% unite(gene, gene, GP, sep = "", na.rm = TRUE)
  } else {
    with_g_p <- with_suffix %>% select(-GP)
  }

  # Combine everything back to a GL string.
  final <- with_g_p %>%
    rename(value = gene) %>%
    ambiguity_table_to_GLstring()
  return(final)
}


globalVariables(c(
  "rest", "molecular_type", "one", "four", "three",
  "two", "gene", "prefix", "code", "suffix", "GP"
))
