# GLstring_genes_expanded

This function processes a specified column in a data frame that contains
GL strings. It separates the GL strings, identifies the HLA loci, and
transforms the data into a wider format with loci as column names. It
also creates multiple rows to separate each locus in the allele.

## Usage

``` r
GLstring_genes_expanded(data, gl_string)
```

## Arguments

- data:

  A data frame containing GL strings for HLA data.

- gl_string:

  The name of the column in the data frame that contains GL strings.

## Value

A data frame with expanded columns, where each row has a single allele
for a specific locus.

## Examples

``` r

file <- HLA_typing_1[, -1]
GL_string <- data.frame("GL_string" = HLA_columns_to_GLstring(
  file,
  HLA_typing_columns = everything()
))
GL_string <- GL_string[1, , drop = FALSE] # When considering first patient
result <- GLstring_genes_expanded(GL_string, "GL_string")
print(result)
#> # A tibble: 2 × 9
#>   A           C           B           DRB5         DRB1  DQA1  DQB1  DPA1  DPB1 
#>   <chr>       <chr>       <chr>       <chr>        <chr> <chr> <chr> <chr> <chr>
#> 1 HLA-A*24:02 HLA-C*07:04 HLA-B*44:02 HLA-DRB5*01… HLA-… HLA-… HLA-… HLA-… HLA-…
#> 2 HLA-A*29:02 HLA-C*16:01 HLA-B*44:03 HLA-DRB5*01… HLA-… HLA-… HLA-… HLA-… HLA-…
```
