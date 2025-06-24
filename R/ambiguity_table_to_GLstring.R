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
#'
#' @importFrom dplyr summarise
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stringr str_flatten

ambiguity_table_to_GLstring <- function(data, remove_duplicates = FALSE) {
  data %>%
    # Remove any identical allele values if remove_duplicates is TRUE and then combine allele ambiguities.
    {
      if (remove_duplicates) distinct(., value, entry, possible_gene_location, locus, genotype_ambiguity, genotype, haplotype, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "/"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype, haplotype)) %>%
    # Remove any identical haplotype values if remove_duplicates is TRUE and then combine alleles in a haplotype.
    {
      if (remove_duplicates) distinct(., value, entry, possible_gene_location, locus, genotype_ambiguity, genotype, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "~"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype)) %>%
    # Remove any identical genotype values if remove_duplicates is TRUE and then combine gene copies to a genotype.
    {
      if (remove_duplicates) distinct(., value, entry, possible_gene_location, locus, genotype_ambiguity, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "+"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity)) %>%
    # Remove any identical genotype ambiguity values if remove_duplicates is TRUE and then combine genotypes to a genotype list.
    {
      if (remove_duplicates) distinct(., value, entry, possible_gene_location, locus, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "|"), .by = c(entry, possible_gene_location, locus)) %>%
    # Remove any identical locus values if remove_duplicates is TRUE and then combine loci.
    {
      if (remove_duplicates) distinct(., value, entry, possible_gene_location, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "^"), .by = c(entry, possible_gene_location)) %>%
    # Remove any identical possible_gene_location values if remove_duplicates is TRUE and then combine possible gene locations to a final GL string.
    {
      if (remove_duplicates) distinct(., value, entry, .keep_all = TRUE) else .
    } %>%
    summarise(value = str_flatten(value, collapse = "?"), .by = entry) %>%
    pull(value)
}

globalVariables(c("."))
