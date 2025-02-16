#' @title ambiguity_table_to_GLstring
#'
#' @description A function that converts a data table of HLA allele ambiguities
#' (e.g. as created by `GLstring_expand_longer`) into a GL string format. The function
#' processes the table by combining allele ambiguities, haplotypes, gene copies,
#' and loci into a structured GL string.
#'
#' @param data A data frame containing columns that represent possible gene
#' locations, loci, genotype ambiguities, genotypes, and haplotypes.
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

ambiguity_table_to_GLstring <- function(data) {
  data %>%
    # Combine allele ambiguities
    summarise(value = str_flatten(value, collapse = "/"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype, haplotype)) %>%
    # Combine alleles in a haplotype
    summarise(value = str_flatten(value, collapse = "~"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype)) %>%
    # Combine gene copies to a genotype
    summarise(value = str_flatten(value, collapse = "+"), .by = c(entry, possible_gene_location, locus, genotype_ambiguity)) %>%
    # Combine genotypes to a genotype list
    summarise(value = str_flatten(value, collapse = "|"), .by = c(entry, possible_gene_location, locus)) %>%
    # Combine loci
    summarise(value = str_flatten(value, collapse = "^"), .by = c(entry, possible_gene_location)) %>%
    # Combine possible gene locations to a final GL string
    summarise(value = str_flatten(value, collapse = "?"), .by = entry) %>%
    # Output a string
    pull(value)
}
