#' @title GLstring_genotype_ambiguity
#'
#' @description This function processes GL strings in the specified columns of
#' a data frame to retain only the first genotype ambiguity, optionally
#' retaining the remaining ambiguities in a separate column with "_ambiguity"
#' appended. The function ensures that genes have been separated from the GL
#' strings prior to execution; otherwise, an error will be thrown if a "^" is
#' detected in the GL strings.
#'
#' @param .data A data frame
#' @param columns The names of the columns in the data frame that contain GL strings
#' @param keep_ambiguities A logical value indicating whether to retain the
#' remaining ambiguities in separate columns with "_genotype_ambiguity" appended
#' to the original column names. Default is FALSE.
#'
#' @return A data frame with the first genotype ambiguity retained in the
#' original columns. If \code{keep_ambiguities} is TRUE, the remaining
#' ambiguities are placed in separate columns.
#'
#' @examples
#' data(toydata)
#' output <- GLstring_genotype_ambiguity(toydata, c("GL_column1", "GL_column2"), keep_ambiguities = TRUE)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom dplyr rename
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr summarize
#' @importFrom dplyr %>%
#' @importFrom stringr str_detect
#' @importFrom stringr str_extract
#' @importFrom stringr str_replace_all
#' @importFrom stringr str_replace
#' @importFrom stringr str_c
#' @importFrom dplyr na_if
#' @importFrom dplyr contains
#' @importFrom rlang abort


GLstring_genotype_ambiguity <- function(.data, columns, keep_ambiguities = FALSE) {
  # Identify the columns to modify
  cols2mod <- names(select(.data, {{columns}}))

  # Set up error detection of "^", which indicates the genes haven't been separated from the GL string.
  (genes_not_separated <- .data %>% mutate(across({{ cols2mod }}, ~str_detect(., "\\^"))) %>%
      summarize(X = toString(across({{ cols2mod }}))) %>%
      mutate(X = str_replace_all(X, "c[:punct:]", " ")) %>%
      mutate(Y = str_detect(X, "TRUE")) %>%
      select(Y)
  )

  # Error code
  if (str_detect(genes_not_separated, "TRUE")) {
    abort("Genes must be separated before `GLstring_genotype_ambiguity` can be used. Process GL strings with the `GLstring_gene_separate` function first.")
  }

  # Copy GL string to a new ambiguity column
  .data %>%
    mutate(across({{ cols2mod }},
                  ~ as.character(.),
                  .names = "{col}_genotype_ambiguity")) %>%
    # Keep the first genotype ambiguity in the original columns
    mutate(across({{ cols2mod }}, ~ str_extract(., "[^|]+"))) %>%
    # Keep the remaining genotype ambiguities in the ambiguity columns
    mutate(across(ends_with("_genotype_ambiguity"), ~ str_replace(., "[^|]+", "")))  %>%
    mutate(across(ends_with("_genotype_ambiguity"), ~ str_replace(., "[\\|]+", ""))) %>%
    mutate(across(ends_with("_genotype_ambiguity"), ~ na_if(., "")))  %>%
    # Drop the ambiguity columns if not wanted
    { if (keep_ambiguities) . else select(., -contains("ambiguity")) }

}
