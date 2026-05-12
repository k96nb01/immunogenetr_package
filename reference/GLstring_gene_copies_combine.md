# GLstring_gene_copies_combine

A function for combining two columns of typing from the same locus into
a single column in the appropriate GL string format.

## Usage

``` r
GLstring_gene_copies_combine(.data, columns, sample_column = "sample")
```

## Arguments

- .data:

  A data frame

- columns:

  The names of the columns in the data frame that contain typing
  information to be combined

- sample_column:

  The name of the column that identifies samples in the data frame.
  Default is "sample".

## Value

A data frame with the specified columns combined into a single column
for each locus, in GL string format.

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
HLA_typing_1 %>%
  mutate(across(A1:B2, ~ HLA_prefix_add(.))) %>%
  GLstring_gene_copies_combine(c(A1:B2), sample_column = patient)
#> # A tibble: 10 × 4
#>    patient HLA_A                   HLA_C                   HLA_B                
#>      <int> <chr>                   <chr>                   <chr>                
#>  1       1 HLA-A*24:02+HLA-A*29:02 HLA-C*07:04+HLA-C*16:01 HLA-B*44:02+HLA-B*44…
#>  2       2 HLA-A*02:01+HLA-A*11:05 HLA-C*07:01+HLA-C*07:02 HLA-B*07:02+HLA-B*08…
#>  3       3 HLA-A*02:01+HLA-A*26:18 HLA-C*02:02+HLA-C*03:04 HLA-B*27:05+HLA-B*54…
#>  4       4 HLA-A*29:02+HLA-A*30:02 HLA-C*06:02+HLA-C*07:01 HLA-B*08:01+HLA-B*13…
#>  5       5 HLA-A*02:05+HLA-A*24:02 HLA-C*07:18+HLA-C*12:03 HLA-B*35:03+HLA-B*58…
#>  6       6 HLA-A*01:01+HLA-A*24:02 HLA-C*07:01+HLA-C*14:02 HLA-B*49:01+HLA-B*51…
#>  7       7 HLA-A*03:01+HLA-A*03:01 HLA-C*03:03+HLA-C*16:01 HLA-B*15:01+HLA-B*51…
#>  8       8 HLA-A*01:01+HLA-A*32:01 HLA-C*06:02+HLA-C*07:02 HLA-B*08:01+HLA-B*37…
#>  9       9 HLA-A*03:01+HLA-A*30:01 HLA-C*07:02+HLA-C*12:03 HLA-B*07:02+HLA-B*38…
#> 10      10 HLA-A*02:05+HLA-A*11:01 HLA-C*07:18+HLA-C*16:02 HLA-B*51:01+HLA-B*58…
```
