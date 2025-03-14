#' @title HLA_column_repair
#'
#' @description This function will change column names that have the official
#'  HLA nomenclature (e.g. "HLA-A*" or "HLA-A") to a format more easily selected
#'  in tidyverse functions (e.g. "HLA_A"). The dash and asterisk are special
#'  characters in R, and makes selecting columns by name difficult. This function
#'  will also allow for easily changing back to WHO-compliant nomenclature
#'  (e.g. "HLA-A*").
#'
#' @param data A data frame
#' @param format Either "tidyverse" or "WHO".
#' @param asterisk Logical value to return column with an asterisk.
#'
#' @return A data frame object with column names renamed in the specified format.
#'
#' @examples
#' HLA_type <- data.frame(
#'   "HLA-A*" = c("01:01", "02:01"),
#'   "HLA-B*" = c("07:02", "08:01"),
#'   "HLA-C*" = c("03:04", "04:01"),
#'   stringsAsFactors = FALSE
#' )
#'
#' HLA_column_repair(HLA_type, format = "tidyverse")
#'
#' @export
#'
#' @importFrom dplyr rename_with
#' @importFrom dplyr %>%
#' @importFrom dplyr starts_with
#' @importFrom stringr str_replace
#' @importFrom rlang abort


HLA_column_repair <- function(data, format = "tidyverse", asterisk = FALSE) {
  # Step 1: turn "HLA-A" to "HLA_A" or vice versa.
  if (format == "tidyverse") {
    step_1 <- data %>% rename_with(~ str_replace(., "HLA\\-", "HLA_"))
  } else if (format == "WHO") {
    step_1 <- data %>% rename_with(~ str_replace(., "HLA_", "HLA-"))
  } else {
    abort("'format' argument must be either 'tidyverse' or 'WHO.'")
  }
  # Step 2: remove asterisk from all columns.
  step_2 <- step_1 %>% rename_with(~ str_replace(., "\\*$", ""))
  # Step 3: add asterisk back if wanted.
  if (asterisk == TRUE) {
    step_3 <- step_2 %>% rename_with(~ str_replace(., "$", "*"), starts_with("HLA"))
  } else {
    step_3 <- step_2
  }
  return(step_3)
}
