# HLA_validate

Returns only HLA alleles in valid nomenclature, either serologic or
molecular. Simple numbers, such as "2" or "27" will be returned as-is.
Suffixes that are not WHO-recognized suffixes (L, S, C, A, Q, N) or G or
P group designations will be removed. For example "novel" at the end of
the allele will be removed, while "n" at the end of the allele will be
retained. Other values, such as "blank" or "-" will be converted to NA
values. This function is helpful for cleaning up the typing of an entire
table of HLA values.

Each value is expected to hold a single allele. If a value contains GL
String delimiters ("^", "\|", "+", "~", "/" or "?"), only the first
allele is retained (the historical behavior, controlled by
\`take_first_allele\`); set \`take_first_allele = FALSE\` to treat such
values as malformed input and get an error instead. Use the GL String
functions (e.g. \`GLstring_expand_longer\`) to work with multi-allele
values.

## Usage

``` r
HLA_validate(data, take_first_allele = TRUE)
```

## Arguments

- data:

  A string containing an HLA allele.

- take_first_allele:

  A logical value. If TRUE (the default), a value containing GL String
  delimiters is silently reduced to its first allele. If FALSE, such
  values raise an error instead, for callers that want malformed
  multi-allele input caught rather than truncated.

## Value

A string with a valid HLA allele or NA if no valid allele was present.

## Examples

``` r
HLA_validate("HLA-A2")
#> [1] "HLA-A2"
HLA_validate("A*02:01:01:01N")
#> [1] "A*02:01:01:01N"
HLA_validate("A*02:01:01N")
#> [1] "A*02:01:01N"
HLA_validate("HLA-DRB1*02:03novel")
#> [1] "HLA-DRB1*02:03"
HLA_validate("HLA-DQB1*03:01v")
#> [1] "HLA-DQB1*03:01"
HLA_validate("HLA-DRB1*02:03P")
#> [1] "HLA-DRB1*02:03P"
HLA_validate("HLA-DPB1*04:01:01G")
#> [1] "HLA-DPB1*04:01:01G"
HLA_validate("2")
#> [1] "2"
HLA_validate(2)
#> [1] "2"
HLA_validate("B27")
#> [1] "B27"
HLA_validate("A*010101")
#> [1] "A*010101"
HLA_validate("-")
#> [1] NA
HLA_validate("blank")
#> [1] NA

# The HLA_typing_LIS dataset contains a table with HLA typing spread across multiple columns:
print(HLA_typing_LIS)
#> # A tibble: 10 × 23
#>    patient mA1Cd.recipient mA2Cd.recipient mB1Cd.recipient mB2Cd.recipient
#>      <int> <chr>           <chr>           <chr>           <chr>          
#>  1       1 24:02           02:01           40:02           "40:01"        
#>  2       2 03:01           74:01           53:01           "57:03"        
#>  3       3 11:01           32:01           52:01           ""             
#>  4       4 03:01           30:02           14:02           ""             
#>  5       5 01:01           24:02           07:02           ""             
#>  6       6 02:01           30:02           39:11           "41:01"        
#>  7       7 02:17           32:01           40:02           ""             
#>  8       8 11:01           23:01           15:17           "44:03"        
#>  9       9 03:01           68:02           08:01           "15:03"        
#> 10      10 01:01           02:01           08:01           "07:02"        
#> # ℹ 18 more variables: mC1Cd.recipient <chr>, mC2Cd.recipient <chr>,
#> #   mDRB11Cd.recipient <chr>, mDRB12Cd.recipient <chr>,
#> #   mDRB31cd.recipient <chr>, mDRB32cd.recipient <chr>,
#> #   mDRB41cd.recipient <chr>, mDRB42cd.recipient <chr>,
#> #   mDRB51cd.recipient <chr>, mDRB52cd.recipient <chr>,
#> #   mDQA11Cd.recipient <chr>, mDQA12Cd.recipient <chr>,
#> #   mDQB11cd.recipient <chr>, mDQB12cd.recipient <chr>, …

# Cleaning up the entire table. Note that blank values will be converted to "NA".
library(dplyr)
HLA_typing_LIS %>% mutate(
  across(
    mA1Cd.recipient:mDPB12cd.recipient,
    ~ HLA_validate(.)
  )
)
#> # A tibble: 10 × 23
#>    patient mA1Cd.recipient mA2Cd.recipient mB1Cd.recipient mB2Cd.recipient
#>      <int> <chr>           <chr>           <chr>           <chr>          
#>  1       1 24:02           02:01           40:02           40:01          
#>  2       2 03:01           74:01           53:01           57:03          
#>  3       3 11:01           32:01           52:01           NA             
#>  4       4 03:01           30:02           14:02           NA             
#>  5       5 01:01           24:02           07:02           NA             
#>  6       6 02:01           30:02           39:11           41:01          
#>  7       7 02:17           32:01           40:02           NA             
#>  8       8 11:01           23:01           15:17           44:03          
#>  9       9 03:01           68:02           08:01           15:03          
#> 10      10 01:01           02:01           08:01           07:02          
#> # ℹ 18 more variables: mC1Cd.recipient <chr>, mC2Cd.recipient <chr>,
#> #   mDRB11Cd.recipient <chr>, mDRB12Cd.recipient <chr>,
#> #   mDRB31cd.recipient <chr>, mDRB32cd.recipient <chr>,
#> #   mDRB41cd.recipient <chr>, mDRB42cd.recipient <chr>,
#> #   mDRB51cd.recipient <chr>, mDRB52cd.recipient <chr>,
#> #   mDQA11Cd.recipient <chr>, mDQA12Cd.recipient <chr>,
#> #   mDQB11cd.recipient <chr>, mDQB12cd.recipient <chr>, …
```
