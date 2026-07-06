# HLA_mismatch_number

Calculates the number of mismatched HLA alleles between a recipient and
a donor across specified loci. Supports mismatch calculations for
host-vs-graft (HvG), graft-vs-host (GvH), or bidirectional.

## Usage

``` r
HLA_mismatch_number(
  GL_string_recip,
  GL_string_donor,
  loci,
  direction,
  homozygous_count = 2
)
```

## Arguments

- GL_string_recip:

  A GL String representing the recipient's HLA genotype.

- GL_string_donor:

  A GL String representing the donor's HLA genotype.

- loci:

  A character vector specifying the loci to be considered for mismatch
  calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
  are considered once locus for this function, and should be called in
  this argument as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.

- direction:

  A character string indicating the direction of mismatch. Options are
  "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional" (the
  max value of "HvG" and "GvH"), or "SOT" (host vs. graft, as is used
  for mismatching in solid organ transplantation).

- homozygous_count:

  An integer specifying how to count homozygous mismatches. Defaults to
  2, where homozygous mismatches are treated as two mismatches,
  regardless if one or two alleles are supplied in the GL String (in
  cases where one allele is supplied, it is duplicated by the function).
  If specified as 1, homozygous mismatches are only counted once,
  regardless of whether one or two alleles are supplied in the GL String
  (in cases where two alleles are supplied, the second identical allele
  is deleted).

## Value

An integer value or a character string: - If \`loci\` includes only one
locus, the function returns an integer mismatch count for that locus. -
If \`loci\` includes multiple loci, the function returns a character
string in the format "Locus1=Count1, Locus2=Count2, ...".

## Examples

``` r

file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")

# Calculate mismatch numbers (Host vs. Graft)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#> [1] "HLA-A=2, HLA-DRB3/4/5=2, HLA-DPB1=0"

# Calculate mismatch numbers (Graft vs. Host)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#> [1] "HLA-A=2, HLA-DRB3/4/5=2, HLA-DPB1=1"

# Calculate mismatch numbers (Bidirectional)
HLA_mismatch_number(GL_string_recip, GL_string_donor,
  loci,
  direction = "bidirectional"
)
#> [1] "HLA-A=2, HLA-DRB3/4/5=2, HLA-DPB1=1"
```
