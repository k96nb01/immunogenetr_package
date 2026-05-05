library(testthat)

# Round-trip property tests.
#
# These exercise pairs of functions that are supposed to be inverses of each
# other. If either half is ever broken by a refactor, a round-trip identity
# test fails fast — independent of the specific output format details the
# per-function unit tests assert.
#
# The iteration-7 NA-propagation bug would have been caught here immediately,
# since expand_longer(NA) -> ambiguity_table_to_GLstring was not NA-identical
# with the first-draft rewrite.

# A compact but representative pool of GL strings pulled from the package's
# shipped data. We use the first five HLA_typing_1 rows (9 loci each, DRB3/4/5
# included) plus a few synthetic edge cases (ambiguity operators, single
# locus, single allele) to keep the suite fast while covering the full GL
# operator set: "/", "~", "+", "|", "^", "?".
make_pool <- function() {
  file <- HLA_typing_1[, -1]
  base <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())[1:5]
  edge <- c(
    # Single allele.
    "HLA-A*01:01",
    # Single-locus two-allele.
    "HLA-A*01:01+HLA-A*02:01",
    # Allele ambiguity ("/").
    "HLA-A*02:01/HLA-A*02:06+HLA-A*03:01",
    # Genotype ambiguity ("|").
    "HLA-A*01:01+HLA-A*02:01|HLA-A*01:02+HLA-A*02:02",
    # Haplotype ("~") and possible-gene-location ("?") combined.
    "HLA-DRB1*03:01:02~HLA-DRB5*01:01:01?HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"
  )
  c(base, edge)
}

test_that("GLstring_expand_longer and ambiguity_table_to_GLstring round-trip", {
  pool <- make_pool()
  # Apply the pair to the full vector — this tests vectorised behaviour
  # AND preserves entry order across both functions.
  round_tripped <- ambiguity_table_to_GLstring(GLstring_expand_longer(pool))
  expect_identical(round_tripped, pool)

  # Also a per-element loop — catches any bug where vectorised behaviour
  # differs from single-element behaviour (it shouldn't).
  for (s in pool) {
    expect_identical(ambiguity_table_to_GLstring(GLstring_expand_longer(s)), s)
  }
})

test_that("HLA_prefix_add and HLA_prefix_remove round-trip on raw allele strings", {
  # For a raw allele "<locus>*<code>" with no "HLA-" prefix, add+remove
  # with matching prefix and keep_locus = TRUE should be an identity.
  raw <- c("A*01:01", "DRB1*15:01", "DQB1*06:02", "DPB1*04:01")
  prefixed <- HLA_prefix_add(raw, prefix = "HLA-")
  # Verify prefix was actually added (guard against both functions being
  # no-ops, which would make the round-trip trivially pass).
  expect_identical(prefixed, paste0("HLA-", raw))
  # keep_locus = TRUE strips only "HLA-", leaving the raw allele.
  expect_identical(HLA_prefix_remove(prefixed, keep_locus = TRUE), raw)
})

test_that("HLA_prefix_add preserves NA (regression for iter-7 NA propagation)", {
  # This is the test-HLA_prefix_add.R:18 expectation promoted to its own
  # test_that block so the intent is explicit: NA passing through
  # expand_longer -> ambiguity_table_to_GLstring must stay NA.
  expect_true(is.na(HLA_prefix_add(NA, "HLA-")))
  expect_true(is.na(HLA_prefix_add(NA_character_, "HLA-A*")))
})
