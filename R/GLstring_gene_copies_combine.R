#' @title GLstring_gene_copies_combine
#'
#' @description A function for combining two columns of typing from the same
#' locus into a single column in the appropriate GL string format.
#'
#' @param .data A data frame
#' @param columns The names of the columns in the data frame that contain typing
#' information to be combined
#' @param sample_column The name of the column that identifies samples in the
#' data frame. Default is "sample".
#'
#' @return A data frame with the specified columns combined into a single column
#' for each locus, in GL string format.
#'
#' @examples
#' output <- data.frame(
#'   sample = c("sample1", "sample2"),
#'   HLA_A1 = c("HLA-A*01:01", "HLA-A*02:01"),
#'   HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
#'   stringsAsFactors = FALSE
#'   )
#' GLstring_gene_copies_combine(output, columns = c("HLA_A1", "HLA_A2"))
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom dplyr mutate
#' @importFrom dplyr filter
#' @importFrom dplyr summarise
#' @importFrom dplyr rename_with
#' @importFrom dplyr %>%
#' @importFrom tidyr pivot_longer
#' @importFrom tidyr pivot_wider
#' @importFrom stringr str_extract
#' @importFrom stringr str_c
#' @importFrom stringr str_replace


GLstring_gene_copies_combine <- function(.data, columns, sample_column = "sample"){
  # Identify the columns to modify
  cols2mod <- names(select(.data, {{columns}}))

  .data %>%
    pivot_longer(all_of(cols2mod), names_to = "locus", values_to = "allele") %>%
    mutate(locus = str_extract(allele, "HLA-[:alnum:]+")) %>%
    filter(!is.na(locus)) %>%
    summarise(allele = str_c(allele, collapse = "+"), .by = c({{sample_column}}, locus)) %>%
    pivot_wider(names_from = locus, values_from = allele) %>%
    rename_with(~ str_replace(., "HLA\\-", "HLA_"))
}
