#' @title GLstring_genotype_ambiguity
#'
#' @description This function processes GL strings in the specified columns of
#' a data frame to retain only the first genotype ambiguity, optionally
#' retaining the remaining ambiguities in a separate column with "_ambiguity"
#' appended. The function ensures that genes have been separated from the GL
#' strings prior to execution; otherwise, an error will be thrown if a "^" is
#' detected in the GL strings.
#'
#' @param data A data frame
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
#' HLA_type <- data.frame(
#'   sample = c("sample1", "sample2"),
#'   HLA_A = c("A*01:01+A*68:01|A*01:02+A*68:55|A*01:99+A*68:66", "A*02:01+A*03:01|A*02:02+A*03:03"),
#'   HLA_B = c("B*07:02+B*58:01|B*07:03+B*58:09", "B*08:01+B*15:01|B*08:02+B*15:17"),
#'   stringsAsFactors = FALSE
#' )
#'
#' GLstring_genotype_ambiguity(HLA_type, columns = c("HLA_A", "HLA_B"), keep_ambiguities = TRUE)
#'
#' @export
#'
#' @importFrom dplyr select
#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr summarize
#' @importFrom dplyr %>%
#' @importFrom dplyr contains
#' @importFrom dplyr na_if
#' @importFrom stringr str_detect
#' @importFrom stringr str_extract
#' @importFrom stringr str_replace_all
#' @importFrom cli cli_abort
#' @importFrom stringr str_replace


GLstring_genotype_ambiguity <- function(data, columns, keep_ambiguities = FALSE) {
  # Validate inputs
  check_data_frame(data, "data")
  check_logical_flag(keep_ambiguities, "keep_ambiguities")

  # Identify the columns to modify
  cols2mod <- names(select(data, {{ columns }}))

  # Check for "^" in any of the selected columns, which indicates genes
  # haven't been separated from the GL string yet.
  if (any(str_detect(unlist(data[cols2mod]), "\\^"), na.rm = TRUE)) {
    cli_abort("Genes must be separated before {.fn GLstring_genotype_ambiguity} can be used. Process GL strings with {.fn GLstring_genes} first.")
  }

  # Copy GL string to a new ambiguity column.
  data %>%
    mutate(across({{ cols2mod }},
      ~ as.character(.),
      .names = "{col}_genotype_ambiguity"
    )) %>%
    # Keep the first genotype ambiguity in the original columns.
    mutate(across({{ cols2mod }}, ~ str_extract(., "[^|]+"))) %>%
    # Remove the first genotype and its trailing pipe from the ambiguity columns,
    # then convert empty strings to NA.
    mutate(across(ends_with("_genotype_ambiguity"), ~ na_if(str_replace(., "^[^|]+\\|?", ""), ""))) %>%
    # Drop the ambiguity columns if not wanted
    {
      if (keep_ambiguities) . else select(., -contains("ambiguity"))
    }
}

globalVariables(c("X", "Y", "ends_with"))
