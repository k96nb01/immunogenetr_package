# HLA_prefix_remove

This function removes HLA and optionally locus prefixes from a string of
HLA typing: "HLA-A2" changes to "A2" or "2". By default, HLA and locus
prefixes are removed. This function also works on each allele in a GL
string.

## Usage

``` r
HLA_prefix_remove(data, keep_locus = FALSE)
```

## Arguments

- data:

  A string with a single HLA allele, a GL string of HLA alleles, or a
  character vector containing either of the previous.

- keep_locus:

  A logical value indicating whether to retain any locus values. The
  default value is FALSE.

## Value

A vector modified to remove HLA and optionally locus prefixes.

## Examples

``` r
# The HLA_typing_1 dataset contains a table with HLA typing spread across multiple columns:
print(HLA_typing_1)
#> # A tibble: 10 × 19
#>    patient A1      A2    C1    C2    B1    B2    DRB345_1 DRB345_2 DRB1_1 DRB1_2
#>      <int> <chr>   <chr> <chr> <chr> <chr> <chr> <chr>    <chr>    <chr>  <chr> 
#>  1       1 A*24:02 A*29… C*07… C*16… B*44… B*44… DRB5*01… DRB5*01… DRB1*… DRB1*…
#>  2       2 A*02:01 A*11… C*07… C*07… B*07… B*08… DRB3*01… DRB4*01… DRB1*… DRB1*…
#>  3       3 A*02:01 A*26… C*02… C*03… B*27… B*54… DRB3*02… DRB4*01… DRB1*… DRB1*…
#>  4       4 A*29:02 A*30… C*06… C*07… B*08… B*13… DRB4*01… DRB4*01… DRB1*… DRB1*…
#>  5       5 A*02:05 A*24… C*07… C*12… B*35… B*58… DRB3*02… DRB3*02… DRB1*… DRB1*…
#>  6       6 A*01:01 A*24… C*07… C*14… B*49… B*51… DRB3*03… DRBX*NN… DRB1*… DRB1*…
#>  7       7 A*03:01 A*03… C*03… C*16… B*15… B*51… DRB4*01… DRBX*NN… DRB1*… DRB1*…
#>  8       8 A*01:01 A*32… C*06… C*07… B*08… B*37… DRB3*02… DRB5*01… DRB1*… DRB1*…
#>  9       9 A*03:01 A*30… C*07… C*12… B*07… B*38… DRB3*01… DRB5*01… DRB1*… DRB1*…
#> 10      10 A*02:05 A*11… C*07… C*16… B*51… B*58… DRB3*03… DRB5*01… DRB1*… DRB1*…
#> # ℹ 8 more variables: DQA1_1 <chr>, DQA1_2 <chr>, DQB1_1 <chr>, DQB1_2 <chr>,
#> #   DPA1_1 <chr>, DPA1_2 <chr>, DPB1_1 <chr>, DPB1_2 <chr>

# The `HLA_prefix_remove` function can be used to get each column to have only the
# colon-separated fields:
library(dplyr)
HLA_typing_1 %>% mutate(
  across(
    A1:DPB1_2,
    ~ HLA_prefix_remove(.)
  )
)
#> # A tibble: 10 × 19
#>    patient A1    A2    C1    C2    B1    B2    DRB345_1 DRB345_2 DRB1_1 DRB1_2
#>      <int> <chr> <chr> <chr> <chr> <chr> <chr> <chr>    <chr>    <chr>  <chr> 
#>  1       1 24:02 29:02 07:04 16:01 44:02 44:03 01:01    01:01    15:01  15:01 
#>  2       2 02:01 11:05 07:01 07:02 07:02 08:01 01:01    01:03    03:01  04:01 
#>  3       3 02:01 26:18 02:02 03:04 27:05 54:01 02:02    01:03    04:04  14:54 
#>  4       4 29:02 30:02 06:02 07:01 08:01 13:02 01:03    01:03    04:01  07:01 
#>  5       5 02:05 24:02 07:18 12:03 35:03 58:01 02:02    02:02    03:01  14:54 
#>  6       6 01:01 24:02 07:01 14:02 49:01 51:01 03:01    NNNN     08:01  13:02 
#>  7       7 03:01 03:01 03:03 16:01 15:01 51:01 01:01    NNNN     01:01  07:01 
#>  8       8 01:01 32:01 06:02 07:02 08:01 37:01 02:02    01:01    03:01  15:01 
#>  9       9 03:01 30:01 07:02 12:03 07:02 38:01 01:01    01:01    03:01  15:01 
#> 10      10 02:05 11:01 07:18 16:02 51:01 58:01 03:01    01:01    13:02  15:01 
#> # ℹ 8 more variables: DQA1_1 <chr>, DQA1_2 <chr>, DQB1_1 <chr>, DQB1_2 <chr>,
#> #   DPA1_1 <chr>, DPA1_2 <chr>, DPB1_1 <chr>, DPB1_2 <chr>
```
