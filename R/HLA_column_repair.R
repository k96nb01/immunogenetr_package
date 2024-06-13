# HLA_column_repair function. This function will change column names that have the official HLA nomenclature (e.g. "HLA-A*" or "HLA-A") to a format supported by R (e.g. "HLA_A"). The dash and asterisk are a special characters in R, and makes selecting columns by name difficult.

HLA_column_repair <- function(data) {
  data %>% rename_with(~ str_replace(., "HLA\\-", "HLA_")) %>% rename_with(~ str_replace(., "\\*$", ""))
}
