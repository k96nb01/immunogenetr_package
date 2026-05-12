# HLA_prefix_add

This function adds a specified prefix to the beginning of each HLA type,
and works on a single allele or all alleles in a GL string. Useful for
adding HLA or gene prefixes.

## Usage

``` r
HLA_prefix_add(data, prefix = "HLA-")
```

## Arguments

- data:

  A string with a single HLA allele, a GL string of HLA alleles, or a
  character vector containing either of the previous.

- prefix:

  A character string to be added as a prefix to the alleles. Default is
  "HLA-".

## Value

A vector with the specified prefix added to the values.

## Examples

``` r
# The HLA_typing_LIS dataset contains a table as might be found in a clinical
# laboratory information system:
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

# The `HLA_prefix_add` function can be used to add the correct HLA prefixes to the table:
library(dplyr)
HLA_typing_LIS %>% mutate(
  across(
    mA1Cd.recipient:mA2Cd.recipient,
    ~ HLA_prefix_add(., "HLA-A*")
  )
)
#> # A tibble: 10 × 23
#>    patient mA1Cd.recipient mA2Cd.recipient mB1Cd.recipient mB2Cd.recipient
#>      <int> <chr>           <chr>           <chr>           <chr>          
#>  1       1 HLA-A*24:02     HLA-A*02:01     40:02           "40:01"        
#>  2       2 HLA-A*03:01     HLA-A*74:01     53:01           "57:03"        
#>  3       3 HLA-A*11:01     HLA-A*32:01     52:01           ""             
#>  4       4 HLA-A*03:01     HLA-A*30:02     14:02           ""             
#>  5       5 HLA-A*01:01     HLA-A*24:02     07:02           ""             
#>  6       6 HLA-A*02:01     HLA-A*30:02     39:11           "41:01"        
#>  7       7 HLA-A*02:17     HLA-A*32:01     40:02           ""             
#>  8       8 HLA-A*11:01     HLA-A*23:01     15:17           "44:03"        
#>  9       9 HLA-A*03:01     HLA-A*68:02     08:01           "15:03"        
#> 10      10 HLA-A*01:01     HLA-A*02:01     08:01           "07:02"        
#> # ℹ 18 more variables: mC1Cd.recipient <chr>, mC2Cd.recipient <chr>,
#> #   mDRB11Cd.recipient <chr>, mDRB12Cd.recipient <chr>,
#> #   mDRB31cd.recipient <chr>, mDRB32cd.recipient <chr>,
#> #   mDRB41cd.recipient <chr>, mDRB42cd.recipient <chr>,
#> #   mDRB51cd.recipient <chr>, mDRB52cd.recipient <chr>,
#> #   mDQA11Cd.recipient <chr>, mDQA12Cd.recipient <chr>,
#> #   mDQB11cd.recipient <chr>, mDQB12cd.recipient <chr>, …
```
