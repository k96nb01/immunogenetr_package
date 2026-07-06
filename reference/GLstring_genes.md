# GLstring_genes

This function processes a specified column in a data frame that contains
GL Strings. It separates the GL Strings, identifies the HLA loci, and
transforms the data into a wider format with loci as column names.

## Usage

``` r
GLstring_genes(data, gl_string)
```

## Arguments

- data:

  A data frame

- gl_string:

  The name of the column in the data frame that contains GL Strings

## Value

A data frame with GL Strings separated, loci identified, and data
transformed to a wider format with loci as columns.

## Examples

``` r

file <- HLA_typing_1[, -1]
GL_string <- data.frame("GL_string" = HLA_columns_to_GLstring(
  file,
  HLA_typing_columns = everything()
))
GL_string <- GL_string[1, , drop = FALSE] # When considering first patient
result <- GLstring_genes(GL_string, "GL_string")
print(result)
#> # A tibble: 1 × 9
#>   HLA_A        HLA_C HLA_B HLA_DRB5 HLA_DRB1 HLA_DQA1 HLA_DQB1 HLA_DPA1 HLA_DPB1
#>   <chr>        <chr> <chr> <chr>    <chr>    <chr>    <chr>    <chr>    <chr>   
#> 1 HLA-A*24:02… HLA-… HLA-… HLA-DRB… HLA-DRB… HLA-DQA… HLA-DQB… HLA-DPA… HLA-DPB…
```
