#' @title GLstring_genes_expanded
#'
#' @description This function processes a specified column in a data frame
#' that contains GL strings. It separates the GL strings, identifies the HLA
#' loci, and transforms the data into a wider format with loci as column names.
#' It also creates multiple rows to separate each locus in the allele.
#'
#' @param data A data frame containing GL strings for HLA data.
#' @param gl_string The name of the column in the data frame that contains
#' GL strings.
#'
#' @return A data frame with expanded columns, where each row has a single
#' allele for a specific locus.
#'
#' @examples
#'
#' file <- HLA_typing_1[, -1]
#' GL_string <- data.frame('GL_string' = HLA_columns_to_GLstring (
#'   file, HLA_typing_columns = everything()))
#' GL_string <- GL_string[1, , drop = FALSE]  # When considering first patient
#' result <- GLstring_genes_expanded(GL_string, "GL_string")
#' View(result)
#'
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr %>%
#' @importFrom tidyr pivot_longer
#' @importFrom tidyr separate_rows
#' @importFrom tidyr pivot_wider
#' @importFrom tidyr unnest


GLstring_genes_expanded <- function(data, gl_string) {
  data %>%
    GLstring_genes(all_of(gl_string)) %>%
    pivot_longer(cols = everything(), names_to = "locus", values_to = "alleles") %>% # Pivot to long format
    mutate(locus = gsub("HLA-|HLA_", "", locus)) %>% # Normalize locus names
    separate_rows(alleles, sep = "\\+") %>% # Separate rows by "+"
    pivot_wider(names_from = locus, values_from = alleles, values_fn = list(alleles = list)) %>% # Pivot back to wide format
    unnest(cols = everything()) # Unnest the columns
}

globalVariables(c("alleles", "everything"))
