#' @title GLstring_genes
#'
#' @description This function processes a specified column in a data frame
#' that contains GL strings. It separates the GL strings, identifies the HLA
#' loci, and transforms the data into a wider format with loci as column names.
#'
#' @param .data A data frame
#' @param gl_string The name of the column in the data frame that contains
#' GL strings
#'
#' @return A data frame with GL strings separated, loci identified, and data
#' transformed to a wider format with loci as columns.
#'
#' @examples
#' table <- tibble(GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01")
#'
#' table %>% GLstring_genes("GL_string")
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

GLstring_genes <- function(.data, gl_string){
  # Identify the columns to modify
  col2mod <- names(select(.data, {{gl_string}}))
  .data %>%
    # Separate the GL string column by the delimiter "^" into multiple rows
    separate_longer_delim({{ col2mod }}, delim = "^") %>%
    # Rename the separated column to "gl_string"
    rename(gl_string = {{ col2mod }}) %>%
    # Extract the locus information from the GL string
    mutate(locus = str_extract(gl_string, "[[:alnum:]-]+(?=\\*)")) %>%
    # Transform the data from long to wide format, using locus names as new column names
    pivot_wider(names_from = locus, values_from = gl_string) %>%
    # Apply the HLA_column_repair function to the transformed data
    HLA_column_repair(.)
}
