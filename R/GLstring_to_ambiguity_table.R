#' @title GLstring_to_ambiguity_table
#'
#' @description A function that expands a GL string into a longer, more detailed
#' format (also known as an ambiguity table) by separating the string into its
#' components resulting from its hierarchical set of operators, including gene
#' locations, loci, genotypes, haplotypes, and alleles. The function processes
#' each level of the GL string and assigns identifiers for each hierarchical
#' component. The resulting table can be assembled back into a GL string using
#' the function `ambiguity_table_to_GLstring`. This function is an alias of
#' `GLstring_expand_longer`.
#'
#' @param GL_string A GL string that encodes HLA alleles and their potential
#' ambiguities
#'
#' @return A tibble that contains the expanded GL string with separate columns
#' for possible gene locations, loci, genotype ambiguities, genotypes, haplotypes,
#' and alleles, each with associated identifiers
#'
#' @examples
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#' result <- GLstring_to_ambiguity_table(GL_string[1])
#' print(result)
#'
#' @export
#'
#'


GLstring_to_ambiguity_table <- function(GL_string) {
  GLstring_expand_longer(GL_string)
}
