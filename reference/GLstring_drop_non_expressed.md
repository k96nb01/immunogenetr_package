# GLstring_drop_non_expressed

This function removes alleles carrying a WHO expression suffix from a GL
String. By default the suffixes N (null), S (secreted) and C
(cytoplasmic) are removed, on the reasoning that these alleles do not
produce a protein at the cell surface; L (low), Q (questionable) and A
(aberrant) alleles are kept, as some surface expression is possible.
Which suffixes to treat as non-expressed is a clinical judgement, so the
\`suffixes\` argument can be set to any combination of the six.

Removal operates on whole alleles at any level of the GL String
hierarchy: an allele ambiguity list narrows, a gene copy with no
expressed alleles collapses, and a locus with no expressed alleles
disappears along with its delimiter. If nothing in a GL String survives,
\`NA\` is returned for that entry.

## Usage

``` r
GLstring_drop_non_expressed(GL_string, suffixes = c("N", "S", "C"))
```

## Arguments

- GL_string:

  A character vector of GL Strings.

- suffixes:

  A character vector of WHO expression suffixes to remove. Any
  combination of "N", "Q", "L", "S", "C" and "A". Defaults to \`c("N",
  "S", "C")\`.

## Value

A character vector of GL Strings with the selected alleles removed, the
same length as \`GL_string\`. Entries with no remaining alleles are
\`NA\`.

## Examples

``` r
# A null allele is removed from an allele ambiguity list, and a gene copy
# with no expressed alleles collapses:
GLstring_drop_non_expressed(
  "HLA-A*01:01N+HLA-A*02:01^HLA-B*07:02/HLA-B*07:02N+HLA-B*08:01"
)
#> [1] "HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"

# A locus with no expressed alleles disappears along with its delimiter:
GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*02:01N^HLA-B*07:02+HLA-B*08:01")
#> [1] "HLA-B*07:02+HLA-B*08:01"

# L, Q and A alleles are kept by default; narrow `suffixes` to remove only
# null alleles:
GLstring_drop_non_expressed("HLA-A*24:02Q+HLA-A*01:01")
#> [1] "HLA-A*24:02Q+HLA-A*01:01"
GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*30:14L", suffixes = "N")
#> [1] "HLA-A*30:14L"
```
