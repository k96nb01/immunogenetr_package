# HLA_column_repair

This function will change column names that have the official HLA
nomenclature (e.g. "HLA-A\*" or "HLA-A") to a format more easily
selected in tidyverse functions (e.g. "HLA_A"). The dash and asterisk
are special characters in R, and makes selecting columns by name
difficult. This function will also allow for easily changing back to
WHO-compliant nomenclature (e.g. "HLA-A\*").

## Usage

``` r
HLA_column_repair(data, format = "tidyverse", asterisk = FALSE)
```

## Arguments

- data:

  A data frame

- format:

  Either "tidyverse" or "WHO".

- asterisk:

  Logical value to return column with an asterisk.

## Value

A data frame object with column names renamed in the specified format.

## Examples

``` r
HLA_type <- data.frame(
  "HLA-A*" = c("01:01", "02:01"),
  "HLA-B*" = c("07:02", "08:01"),
  "HLA-C*" = c("03:04", "04:01"),
  stringsAsFactors = FALSE
)

HLA_column_repair(HLA_type, format = "tidyverse")
#>   HLA.A. HLA.B. HLA.C.
#> 1  01:01  07:02  03:04
#> 2  02:01  08:01  04:01
```
