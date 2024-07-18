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
#' data(toydata)
#' output <- GLstring_genes_expanded(toydata, "GL_column")
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom dplyr rename
#' @importFrom dplyr mutate
#' @importFrom dplyr %>%
#' @importFrom tidyr separate_longer_delim
#' @importFrom tidyr pivot_wider
#' @importFrom stringr str_extract

GLstring_genes_expanded <- function(data, gl_string) {
  data %>%
    GLstring_genes(gl_string) %>%
    pivot_longer(cols = everything(), names_to = "locus", values_to = "alleles") %>%  # Pivot to long format
    separate_rows(alleles, sep = "\\+") %>%  # Separate rows by "+"
    pivot_wider(names_from = locus, values_from = alleles, values_fn = list(alleles = list)) %>%  # Pivot back to wide format
    unnest(cols = everything())  # Unnest the columns
}
