# GLstring_regex

This function will format an HLA allele (e.g. "HLA-A\*02:01") to a regex
pattern for searching within a GL String. Note that in order for this
function to work properly, the full HLA allele name, including prefixes,
is required. Allele values of "A\*02:01" will need to be updated to
"HLA-A\*02:01", and "A2" will need to be updated to "HLA-A2". The
\`HLA_prefix_add\` function is useful in these situations.

## Usage

``` r
GLstring_regex(data)
```

## Arguments

- data:

  A string containing an HLA allele.

## Value

A string with the HLA allele formatted as a regex pattern.

## Examples

``` r

# To understand how the function works we can see how it alters the allele "HLA-A*02:01":

GLstring_regex("HLA-A*02:01")
#> [1] "HLA-A\\*02:01(?=(\\?|\\^|\\||\\+|\\~|/|:|$))"

# The result is the same allele with extra formatting to escape special characters found
# in a GL String, as well as the ability to accurately search for an allele in a GL String.
# For example, we would not want the allele "HLA-A*02:14" to match to "HLA-A*02:149:01",
# which would happen if we simply escaped the special characters:

library(stringr)
str_view("HLA-A*02:149:01", str_escape("HLA-A*02:14"), match = NA)
#> [1] │ <HLA-A*02:14>9:01

# Using `GLstring_regex` prevents this:

str_view("HLA-A*02:149:01", GLstring_regex("HLA-A*02:14"), match = NA)
#> [1] │ HLA-A*02:149:01

# Using a longer GL String with multiple alleles and loci:

GL_string <- "HLA-A*02:01:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01"

# We can match any allele accurately:

str_view(GL_string, GLstring_regex("HLA-A*68:01"), match = NA)
#> [1] │ HLA-A*02:01:01+<HLA-A*68:01>^HLA-B*07:01+HLA-B*15:01

# Note that alleles supplied with fewer fields than in the GL String will also match:

str_view(GL_string, GLstring_regex("HLA-A*02:01"), match = NA)
#> [1] │ <HLA-A*02:01>:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01
```
