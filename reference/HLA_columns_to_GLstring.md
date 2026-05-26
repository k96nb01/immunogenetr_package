# HLA_columns_to_GLstring

A function to take HLA typing data spread across different columns, as
is often found in wild-caught data, and transform it to a GL string. If
column names have anything besides the locus name and a number (e.g.
"mA1Cd" instead of just "A1"), the function will have trouble
determining the locus from the column name. The \`prefix_to_remove\` and
\`suffix_to_remove\` arguments can be used to clean up the column names.
See the example for how these arguments are used.

## Usage

``` r
HLA_columns_to_GLstring(
  data,
  HLA_typing_columns,
  prefix_to_remove = "",
  suffix_to_remove = ""
)
```

## Arguments

- data:

  A data frame with each row including an HLA typing result, with
  individual columns containing a single allele.

- HLA_typing_columns:

  A list of columns containing the HLA alleles. Tidyselect is supported.

- prefix_to_remove:

  An optional string of characters to remove from the locus names. The
  goal is to get the column names to the locus and a number. For
  example, columns named "mDRB11Cd" and "mDRB12Cd" should use the
  \`prefix_to_remove\` value of "m".

- suffix_to_remove:

  An optional string of characters to remove from the locus names. Using
  the example above, the \`suffix_to_remove\` value will be "Cd".

## Value

A list of GL strings in the order of the original data frame.

## Examples

``` r
# The HLA_typing_LIS dataset contains a table as might be found in a clinical laboratory
# information system:
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

# The `HLA_columns_to_GLString` function can be used to coerce typing spread across
# multiple columns into a GL string:
library(dplyr)
HLA_typing_LIS %>%
  mutate(
    GL_string = HLA_columns_to_GLstring(
      ., # Note that if this function is used inside a `mutate` call "." will have to be
      # used as the first argument to extract data from the working data frame.
      HLA_typing_columns = mA1Cd.recipient:mDPB12cd.recipient,
      prefix_to_remove = "m",
      suffix_to_remove = "Cd.recipient"
    ),
    .after = patient
  ) %>%
  select(patient, GL_string)
#> # A tibble: 10 × 2
#>    patient GL_string                                                            
#>      <int> <chr>                                                                
#>  1       1 HLA-A*24:02+HLA-A*02:01^HLA-B*40:02+HLA-B*40:01^HLA-C*03:04^HLA-DRB1…
#>  2       2 HLA-A*03:01+HLA-A*74:01^HLA-B*53:01+HLA-B*57:03^HLA-C*04:01+HLA-C*07…
#>  3       3 HLA-A*11:01+HLA-A*32:01^HLA-B*52:01^HLA-C*12:02^HLA-DRB1*15:02^HLA-D…
#>  4       4 HLA-A*03:01+HLA-A*30:02^HLA-B*14:02^HLA-C*08:02^HLA-DRB1*01:02+HLA-D…
#>  5       5 HLA-A*01:01+HLA-A*24:02^HLA-B*07:02^HLA-C*07:02^HLA-DRB1*01:01+HLA-D…
#>  6       6 HLA-A*02:01+HLA-A*30:02^HLA-B*39:11+HLA-B*41:01^HLA-C*07:02+HLA-C*17…
#>  7       7 HLA-A*02:17+HLA-A*32:01^HLA-B*40:02^HLA-C*02:02+HLA-C*03:05^HLA-DRB1…
#>  8       8 HLA-A*11:01+HLA-A*23:01^HLA-B*15:17+HLA-B*44:03^HLA-C*07:01+HLA-C*16…
#>  9       9 HLA-A*03:01+HLA-A*68:02^HLA-B*08:01+HLA-B*15:03^HLA-C*02:10+HLA-C*03…
#> 10      10 HLA-A*01:01+HLA-A*02:01^HLA-B*08:01+HLA-B*07:02^HLA-C*07:01+HLA-C*05…
```
