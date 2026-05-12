# HLA_match_summary_HCT

Calculates the match summary for either the HLA-A, B, C and DRB1 loci
(out-of-8 matching) or the HLA-A, B, C, DRB1 and DQB1 loci (out-of-10
matching), as is commonly used for hematopoietic cell transplantation
(HCT). Homozygous mismatches are counted twice. Bidirectional matching
is the default, but can be overridden with the "direction" argument.

## Usage

``` r
HLA_match_summary_HCT(
  GL_string_recip,
  GL_string_donor,
  direction = "bidirectional",
  match_grade,
  scope = "locus"
)
```

## Arguments

- GL_string_recip:

  A GL string representing the recipient's HLA genotype, and minimally
  containing the HLA-A, B, C and DRB1 loci (for Xof8 matching) or the
  HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).

- GL_string_donor:

  A GL string representing the donor's HLA genotype, and minimally
  containing the HLA-A, B, C and DRB1 loci (for Xof8 matching) or the
  HLA-A, B, C, DRB1 and DQB1 loci (for Xof10 matching).

- direction:

  "GvH", "HvG" or "bidirectional". Default is "bidirectional".

- match_grade:

  "Xof8" for HLA-A, B, C and DRB1 matching or "Xof10" for HLA-A, B, C,
  DRB1 and DQB1 matching.

- scope:

  "locus" or "genotype". Default is "locus". When "locus" (the default),
  bidirectional matching takes the minimum match count at each locus
  independently before summing. When "genotype", the GvH and HvG match
  summaries are calculated separately across all loci, and the maximum
  of the two totals is returned. Only affects results when direction is
  "bidirectional"; ignored otherwise.

## Value

An integer value of the match grade summary.

## Examples

``` r
# Example recipient and donor GL strings
file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

# Calculate mismatch numbers
HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
  direction = "bidirectional", match_grade = "Xof8"
)
#> [1] 0

# Genotype-level bidirectional matching (max of GvH and HvG totals)
HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
  direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
)
#> [1] 0
```
