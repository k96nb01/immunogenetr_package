# GLstring_expand_longer

A function that expands a GL string into a longer, more detailed format
(also known as an ambiguity table) by separating the string into its
components resulting from its hierarchical set of operators, including
gene locations, loci, genotypes, haplotypes, and alleles. The function
processes each level of the GL string and assigns identifiers for each
hierarchical component. The resulting table can be assembled back into a
GL string using the function \`ambiguity_table_to_GLstring\`.

## Usage

``` r
GLstring_expand_longer(GL_string)
```

## Arguments

- GL_string:

  A GL string that encodes HLA alleles and their potential ambiguities

## Value

A tibble that contains the expanded GL string with separate columns for
possible gene locations, loci, genotype ambiguities, genotypes,
haplotypes, and alleles, each with associated identifiers

## Examples

``` r
file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
result <- GLstring_expand_longer(GL_string[1])
print(result)
#> # A tibble: 18 × 8
#>    value          entry possible_gene_location locus genotype_ambiguity genotype
#>    <chr>          <int>                  <int> <int>              <int>    <int>
#>  1 HLA-A*24:02        1                      1     1                  1        1
#>  2 HLA-A*29:02        1                      1     1                  1        2
#>  3 HLA-C*07:04        1                      1     2                  1        1
#>  4 HLA-C*16:01        1                      1     2                  1        2
#>  5 HLA-B*44:02        1                      1     3                  1        1
#>  6 HLA-B*44:03        1                      1     3                  1        2
#>  7 HLA-DRB5*01:01     1                      1     4                  1        1
#>  8 HLA-DRB5*01:01     1                      1     4                  1        2
#>  9 HLA-DRB1*15:01     1                      1     5                  1        1
#> 10 HLA-DRB1*15:01     1                      1     5                  1        2
#> 11 HLA-DQA1*01:02     1                      1     6                  1        1
#> 12 HLA-DQA1*01:02     1                      1     6                  1        2
#> 13 HLA-DQB1*06:02     1                      1     7                  1        1
#> 14 HLA-DQB1*06:02     1                      1     7                  1        2
#> 15 HLA-DPA1*01:03     1                      1     8                  1        1
#> 16 HLA-DPA1*01:03     1                      1     8                  1        2
#> 17 HLA-DPB1*03:01     1                      1     9                  1        1
#> 18 HLA-DPB1*04:01     1                      1     9                  1        2
#> # ℹ 2 more variables: haplotype <int>, allele <int>
```
