# ambiguity_table_to_GLstring

A function that converts a data table of HLA allele ambiguities (e.g. as
created by \`GLstring_expand_longer\` or
\`GLstring_to_ambiguity_table\`) into a GL String format. The function
processes the table by combining allele ambiguities, haplotypes, gene
copies, and loci into a structured GL String.

## Usage

``` r
ambiguity_table_to_GLstring(data, remove_duplicates = FALSE)
```

## Arguments

- data:

  A data frame containing columns that represent possible gene
  locations, loci, genotype ambiguities, genotypes, and haplotypes.

- remove_duplicates:

  A logical value indicating if the function will check for duplicate
  entries at each step and remove them before assembling the final GL
  String. Useful if the ambiguity table has been altered, for example by
  truncating allele designations. Default is FALSE.

## Value

A GL String representing the combined gene locations, loci, genotype
ambiguities, genotypes, and haplotypes. A zero-row table returns
\`character(0)\`, so filtered pipelines (e.g. \`GLstring_expand_longer\`
followed by a \`dplyr::filter\` that removes every row) compose without
special-casing.

## Examples

``` r
# Example data frame input
data <- tibble::tribble(
  ~value, ~entry, ~possible_gene_location,
  ~locus, ~genotype_ambiguity, ~genotype, ~haplotype, ~allele,
  "HLA-A*01:01:01:01", 1, 1,
  1, 1, 1, 1, 1,
  "HLA-A*01:02", 1, 1,
  1, 1, 1, 1, 2,
  "HLA-A*01:03", 1, 1,
  1, 1, 1, 1, 3,
  "HLA-A*01:95", 1, 1,
  1, 1, 1, 1, 4,
  "HLA-A*24:02:01:01", 1, 1,
  1, 1, 2, 1, 1,
  "HLA-A*01:01:01:01", 1, 1,
  1, 2, 1, 1, 1,
  "HLA-A*01:03", 1, 1,
  1, 2, 1, 1, 2,
  "HLA-A*24:03:01:01", 1, 1,
  1, 2, 2, 1, 1,
  "HLA-B*07:01:01", 1, 1,
  2, 1, 1, 1, 1,
  "B*15:01:01", 1, 1,
  2, 1, 2, 1, 1,
  "B*15:02:01", 1, 1,
  2, 1, 2, 1, 2,
  "B*07:03", 1, 1,
  2, 2, 1, 1, 1,
  "B*15:99:01", 1, 1,
  2, 2, 2, 1, 1,
  "HLA-DRB1*03:01:02", 1, 1,
  3, 1, 1, 1, 1,
  "HLA-DRB5*01:01:01", 1, 1,
  3, 1, 1, 2, 1,
  "HLA-KIR2DL5A*0010101", 1, 1,
  3, 1, 2, 1, 1,
  "HLA-KIR2DL5A*0010201", 1, 1,
  3, 1, 3, 1, 1,
  "HLA-KIR2DL5B*0010201", 1, 2,
  1, 1, 1, 1, 1,
  "HLA-KIR2DL5B*0010301", 1, 2,
  1, 1, 2, 1, 1
)

ambiguity_table_to_GLstring(data)
#> [1] "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A*01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01^HLA-B*07:01:01+B*15:01:01/B*15:02:01|B*07:03+B*15:99:01^HLA-DRB1*03:01:02~HLA-DRB5*01:01:01+HLA-KIR2DL5A*0010101+HLA-KIR2DL5A*0010201?HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"
```
