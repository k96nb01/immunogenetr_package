#' @title ambiguity_table_to_GLstring
#'
#' @description A function that converts a data table of HLA allele ambiguities
#' into a GL string format. The function processes the table by combining allele
#' ambiguities, haplotypes, gene copies, and loci into a structured GL string.
#'
#' @param data A data frame containing columns that represent possible gene
#' locations, loci, genotype ambiguities, genotypes, and haplotypes.
#'
#' @return A GL string representing the combined gene locations, loci, genotype
#' ambiguities, genotypes, and haplotypes.
#'
#' @examples
#' # Example data frame input
#' data <- tibble(
#'   value = c(
#'     "HLA-A*01:01:01:01", "HLA-A*01:02", "HLA-A*01:03", "HLA-A*01:95",
#'     "HLA-A*24:02:01:01", "HLA-A*01:01:01:01", "HLA-A*01:03",
#'     "HLA-A*24:03:01:01", "HLA-B*07:01:01", "B*15:01:01"),
#'   possible_gene_location = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
#'   locus = c("HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A",
#'     "HLA-A", "HLA-B", "HLA-B"),
#'   genotype_ambiguity = c(1, 1, 1, 1, 1, 2, 2, 2, 1, 1),
#'   genotype = c(1, 1, 1, 1, 2, 1, 1, 2, 1, 2),
#'   haplotype = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
#'   allele = c(1, 2, 3, 4, 1, 1, 2, 1, 1, 1)
#' )
#' result <- ambiguity_table_to_GLstring(data)
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr summarise
#' @importFrom dplyr pull
#' @importFrom dplyr %>%
#' @importFrom stringr str_flatten

ambiguity_table_to_GLstring <- function(data){
  data %>%
    # Combine allele ambiguities
    summarise(value = str_flatten(value, collapse = "/"), .by = c(possible_gene_location, locus, genotype_ambiguity, genotype, haplotype)) %>%
    # Combine alleles in a haplotype
    summarise(value = str_flatten(value, collapse = "~"), .by = c(possible_gene_location, locus, genotype_ambiguity, genotype)) %>%
    # Combine gene copies to a genotype
    summarise(value = str_flatten(value, collapse = "+"), .by = c(possible_gene_location, locus, genotype_ambiguity)) %>%
    # Combine genotypes to a genotype list
    summarise(value = str_flatten(value, collapse = "|"), .by = c(possible_gene_location, locus)) %>%
    # Combine loci
    summarise(value = str_flatten(value, collapse = "^"), .by = possible_gene_location) %>%
    # Combine possible gene locations to a final GL string
    summarise(value = str_flatten(value, collapse = "?")) %>%
    # Output a string
    pull(value)
}
