#' @title GLstring_expand_longer
#'
#' @description A function that expands a GL string into a longer, more detailed
#' format (also known as an ambiguity table) by separating the string into its
#' components resulting from its hierarchical set of operators, including gene
#' locations, loci, genotypes, haplotypes, and alleles. The function processes
#' each level of the GL string and assigns identifiers for each hierarchical
#' component. The resulting table can be assembled back into a GL string using
#' the function `ambiguity_table_to_GLstring`.
#'
#' @param GL_string A GL string that encodes HLA alleles and their potential
#' ambiguities
#'
#' @return A tibble that contains the expanded GL string with separate columns
#' for possible gene locations, loci, genotype ambiguities, genotypes, haplotypes,
#' and alleles, each with associated identifiers
#'
#' @examples
#' GL_string <- "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A
#'   *01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01
#'   ^HLA-B*07:01:01+B*15:01:01/B*15:02:01|B*07:03+B*15:99:01^HLA-DRB1*03:01:02
#'   ~HLA-DRB5*01:01:01+HLA-KIR2DL5A*0010101+HLA-KIR2DL5A*0010201?
#'   HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"
#' result <- GLstring_expand_longer(GL_string)
#' print(result)
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr row_number
#' @importFrom dplyr %>%
#' @importFrom tidyr separate_longer_delim
#' @importFrom tibble as_tibble
#'


GLstring_expand_longer <- function(GL_string) {
  as_tibble(GL_string) %>%
    # Assign a unique identifier for each entry for the function
    mutate(entry = row_number()) %>%
    # Separate GL string precedence 0: possible gene locations
    separate_longer_delim(value, delim = "?") %>%
    # Assign a unique identifier for each possible gene location
    mutate(possible_gene_location = row_number(), .by = entry) %>%
    # Separate GL string precedence 1: gene/locus
    separate_longer_delim(value, delim = "^") %>%
    # Identify locus
    mutate(locus = row_number(), .by = c(entry, possible_gene_location)) %>%
    # Separate GL string precedence 2: genotype list
    separate_longer_delim(value, delim = "|") %>%
    # Identify genotype ambiguities
    mutate(genotype_ambiguity = row_number(), .by = c(entry, possible_gene_location, locus)) %>%
    # Separate GL string precedence 3: genotype
    separate_longer_delim(value, delim = "+") %>%
    # Identify genotypes
    mutate(genotype = row_number(), .by = c(entry, possible_gene_location, locus, genotype_ambiguity)) %>%
    # Separate GL string precedence 4: haplotype
    separate_longer_delim(value, delim = "~") %>%
    # Identify haplotypes
    mutate(haplotype = row_number(), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype)) %>%
    # Separate GL string precedence 5: allele list
    separate_longer_delim(value, delim = "/") %>%
    # Identify alleles
    mutate(allele = row_number(), .by = c(entry, possible_gene_location, locus, genotype_ambiguity, genotype, haplotype))
}

globalVariables(c(
  "value", "entry", "possible_gene_location", "locus",
  "genotype_ambiguity", "genotype", "haplotype", "allele"
))
