# GLstring_genotype_ambiguity

This function processes GL Strings in the specified columns of a data
frame to retain only the first genotype ambiguity, optionally retaining
the remaining ambiguities in a separate column with "\_ambiguity"
appended. The function ensures that genes have been separated from the
GL strings prior to execution; otherwise, an error will be thrown if a
"^" is detected in the GL Strings.

## Usage

``` r
GLstring_genotype_ambiguity(data, columns, keep_ambiguities = FALSE)
```

## Arguments

- data:

  A data frame

- columns:

  The names of the columns in the data frame that contain GL Strings

- keep_ambiguities:

  A logical value indicating whether to retain the remaining ambiguities
  in separate columns with "\_genotype_ambiguity" appended to the
  original column names. Default is FALSE.

## Value

A data frame with the first genotype ambiguity retained in the original
columns. If `keep_ambiguities` is TRUE, the remaining ambiguities are
placed in separate columns.

## Examples

``` r
HLA_type <- data.frame(
  sample = c("sample1", "sample2"),
  HLA_A = c("A*01:01+A*68:01|A*01:02+A*68:55|A*01:99+A*68:66", "A*02:01+A*03:01|A*02:02+A*03:03"),
  HLA_B = c("B*07:02+B*58:01|B*07:03+B*58:09", "B*08:01+B*15:01|B*08:02+B*15:17"),
  stringsAsFactors = FALSE
)

GLstring_genotype_ambiguity(HLA_type, columns = c("HLA_A", "HLA_B"), keep_ambiguities = TRUE)
#>    sample           HLA_A           HLA_B        HLA_A_genotype_ambiguity
#> 1 sample1 A*01:01+A*68:01 B*07:02+B*58:01 A*01:02+A*68:55|A*01:99+A*68:66
#> 2 sample2 A*02:01+A*03:01 B*08:01+B*15:01                 A*02:02+A*03:03
#>   HLA_B_genotype_ambiguity
#> 1          B*07:03+B*58:09
#> 2          B*08:02+B*15:17
```
