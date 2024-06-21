#' @title HLA_column_repair
#'
#' @description This function will change column names that have the official
#'  HLA nomenclature (e.g. "HLA-A*" or "HLA-A") to a format more easily selected
#'  in tidyverse function (e.g. "HLA_A"). The dash and asterisk are a special
#'  characters in R, and makes selecting columns by name difficult. This function
#'  will also allow for easily changing back to WHO-compliant nomenlcautre
#'  (e.g. "HLA-A*").
#'
#' @param data A data frame
#'
#' @return A data frame object with column names renamed in the "HLA_A" format.
#'
#' @examples
#' data(toydata) # I think we need to make some toydata.
#' output <- HLA_column_repair(toydata)
#' @export
#' @importFrom dplyr "%>%"

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
