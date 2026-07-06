# HLA_truncate

This function truncates HLA typing values in molecular nomenclature (for
example from 4 fields to 2 fields). The truncation is based on the
number of fields specified and optionally retains any WHO-recognized
suffixes (L, S, C, A, Q, or N) or G and P group designations (G or P).
This function will work on individual alleles (e.g.
"HLA-A\*02:01:01:01") or on all alleles in a GL String (e.g.
"HLA-A\*02:01:01:01+HLA-A\*68:01:01^HLA-DRB1\*01:01:01+HLA-DRB1\*03:01:01").

Note: depending on arguments used, this function can output HLA alleles
that do not exist in the IPD-IMGT/HLA database. For example, truncating
the allele "DRB4\*01:03:01:02N" to 2 fields would result in
"DRB4\*01:03N," which does not exist in the IPD-IMGT/HLA database. Users
should take care in setting the parameters for this function.

## Usage

``` r
HLA_truncate(
  data,
  fields = 2,
  keep_suffix = TRUE,
  keep_G_P_group = FALSE,
  remove_duplicates = FALSE
)
```

## Arguments

- data:

  A string containing an HLA allele or a GL String.

- fields:

  An integer specifying the number of fields to retain in the truncated
  values. Default is 2.

- keep_suffix:

  A logical value indicating whether to retain any WHO-recognized
  suffixes. Default is TRUE.

- keep_G_P_group:

  A logical value indicating whether to retain any G or P group
  designations. Default is FALSE.

- remove_duplicates:

  A logical value indicating whether to remove duplicated values from a
  GL String after truncation. Default is FALSE.

## Value

A string with the HLA typing truncated according to the specified number
of fields and optional suffix retention.

## Examples

``` r

# The Haplotype_frequencies dataset contains a table with HLA typing spread across multiple columns:
print(Haplotype_frequencies)
#> # A tibble: 10 × 12
#>    `HLA-A`       `HLA-C`   `HLA-B` `HLA-DRB345` `HLA-DRB1` `HLA-DQA1` `HLA-DQB1`
#>    <chr>         <chr>     <chr>   <chr>        <chr>      <chr>      <chr>     
#>  1 A*24:02:01:01 C*03:04:… B*40:0… Abs          DRB1*08:0… DQA1*04:0… DQB1*04:0…
#>  2 A*03:01:01:05 C*06:02:… B*47:0… DRB4*01:01:… DRB1*07:0… DQA1*02:0… DQB1*02:0…
#>  3 A*02:01:01:01 C*05:01:… B*44:0… DRB3*01:01:… DRB1*03:0… DQA1*05:0… DQB1*02:0…
#>  4 A*32:01:01    C*02:02:… B*40:0… DRB3*02:02:… DRB1*11:0… DQA1*05:0… DQB1*03:0…
#>  5 A*02:01:01:01 C*05:01:… B*44:0… DRB5*01:01:… DRB1*15:0… DQA1*01:0… DQB1*06:0…
#>  6 A*02:01:01:01 C*05:01:… B*44:0… DRB4*01:03:… DRB1*04:0… DQA1*03:0… DQB1*03:0…
#>  7 A*02:06:01:01 C*08:01:… B*40:0… DRB4*01:03:… DRB1*09:0… DQA1*03:02 DQB1*03:0…
#>  8 A*24:02:01:01 C*07:02:… B*39:0… DRB5*02:02   DRB1*16:0… DQA1*05:0… DQB1*03:0…
#>  9 A*02:01:01:01 C*02:02:… B*40:0… DRB3*02:02:… DRB1*13:0… DQA1*01:0… DQB1*06:0…
#> 10 A*24:02:01:01 C*07:04:… B*44:0… DRB3*02:02:… DRB1*11:0… DQA1*05:0… DQB1*03:0…
#> # ℹ 5 more variables: `HLA-DPA1` <chr>, `HLA-DPB1` <chr>, Global_Fq <dbl>,
#> #   Global_n <int>, Global_rank <int>

# The `HLA_truncate` function can be used to truncate the typing results to 2 fields:
library(dplyr)
Haplotype_frequencies %>% mutate(
  across(
    "HLA-A":"HLA-DPB1",
    ~ HLA_truncate(
      .,
      fields = 2,
      keep_suffix = TRUE,
      keep_G_P_group = FALSE
    )
  )
)
#> # A tibble: 10 × 12
#>    `HLA-A` `HLA-C` `HLA-B` `HLA-DRB345`         `HLA-DRB1` `HLA-DQA1` `HLA-DQB1`
#>    <chr>   <chr>   <chr>   <chr>                <chr>      <chr>      <chr>     
#>  1 A*24:02 C*03:04 B*40:01 Abs                  DRB1*08:01 DQA1*04:01 DQB1*04:02
#>  2 A*03:01 C*06:02 B*47:01 DRB4*01:01           DRB1*07:01 DQA1*02:01 DQB1*02:02
#>  3 A*02:01 C*05:01 B*44:02 DRB3*01:01           DRB1*03:01 DQA1*05:01 DQB1*02:01
#>  4 A*32:01 C*02:02 B*40:02 DRB3*02:02           DRB1*11:01 DQA1*05:05 DQB1*03:01
#>  5 A*02:01 C*05:01 B*44:02 DRB5*01:01           DRB1*15:01 DQA1*01:02 DQB1*06:02
#>  6 A*02:01 C*05:01 B*44:02 DRB4*01:03/DRB4*01:… DRB1*04:01 DQA1*03:03 DQB1*03:01
#>  7 A*02:06 C*08:01 B*40:06 DRB4*01:03           DRB1*09:01 DQA1*03:02 DQB1*03:0…
#>  8 A*24:02 C*07:02 B*39:05 DRB5*02:02           DRB1*16:02 DQA1*05:05 DQB1*03:01
#>  9 A*02:01 C*02:02 B*40:02 DRB3*02:02           DRB1*13:01 DQA1*01:03 DQB1*06:03
#> 10 A*24:02 C*07:04 B*44:02 DRB3*02:02           DRB1*11:01 DQA1*05:05 DQB1*03:01
#> # ℹ 5 more variables: `HLA-DPA1` <chr>, `HLA-DPB1` <chr>, Global_Fq <dbl>,
#> #   Global_n <int>, Global_rank <int>
```
