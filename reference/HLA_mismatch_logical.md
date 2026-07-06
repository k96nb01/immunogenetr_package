# HLA_mismatch_logical

Determines if there are any mismatches between recipient and donor HLA
alleles for the specified loci. Returns \`TRUE\` if mismatches are
present, and \`FALSE\` otherwise.

## Usage

``` r
HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, direction)
```

## Arguments

- GL_string_recip:

  A GL Strings representing the recipient's HLA genotypes.

- GL_string_donor:

  A GL Strings representing the donor's HLA genotypes.

- loci:

  A character vector specifying the loci to be considered for mismatch
  calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
  are considered once locus for this function, and should be called in
  this argument as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.

- direction:

  A character string indicating the direction of mismatch. Options are
  "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional" (if
  either "HvG" or "GvH" is TRUE), or "SOT" (host vs. graft, as is used
  for mismatching in solid organ transplantation).

## Value

A logical value (\`TRUE\` or \`FALSE\`): - \`TRUE\` if there are
mismatches between recipient and donor HLA alleles. - \`FALSE\` if there
are no mismatches.

## Examples

``` r

file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
mismatches <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)
#> [1] "HLA-A=TRUE, HLA-DRB3/4/5=TRUE, HLA-DPB1=FALSE"
```
