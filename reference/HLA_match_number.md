# HLA_match_number

Calculates the number of HLA matches as two minus the number of
mismatches from \`HLA_mismatch_number\`. Homozygous mismatches are
counted twice. Supports match calculations for host-vs-graft (HvG),
graft-vs-host (GvH), or bidirectional. Bidirectional matching is the
default, but can be overridden using the "direction" argument.

## Usage

``` r
HLA_match_number(
  GL_string_recip,
  GL_string_donor,
  loci,
  direction = "bidirectional"
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

  A character string indicating the direction of match. Options are
  "HvG" (host vs. graft), "GvH" (graft vs. host), "bidirectional" (the
  minimum value of "HvG" and "GvH").

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

loci <- c("HLA-A", "HLA-B")

# Calculate mismatch numbers (Host vs. Graft)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#> [1] "HLA-A=0, HLA-B=0"

# Calculate mismatch numbers (Graft vs. Host)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
#> [1] "HLA-A=0, HLA-B=0"

# Calculate mismatch numbers (Bidirectional)
HLA_match_number(GL_string_recip, GL_string_donor,
  loci,
  direction = "bidirectional"
)
#> [1] "HLA-A=0, HLA-B=0"
```
