library(testthat)

# NA propagation through the matching/mismatching family.
#
# A pair with missing typing on either side must come back NA — not FALSE, not
# 0 mismatches, not 2 matches — while the remaining pairs are computed
# normally. The single-locus paths are the ones at risk: HLA_mismatch_base
# returns NA_character_ both for "no data" and for "no mismatches", so each
# wrapper distinguishes the two from its inputs, not from the base output.

recip_single <- c("HLA-A*01:01+HLA-A*02:01", NA)
donor_single <- c("HLA-A*01:01+HLA-A*03:01", "HLA-A*01:01+HLA-A*02:01")

recip_multi <- c("HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01", NA)
donor_multi <- c("HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02", "HLA-A*01:01^HLA-B*07:02")

test_that("HLA_mismatch_number returns NA for NA pairs", {
  expect_equal(
    HLA_mismatch_number(recip_single, donor_single, "HLA-A", "HvG"),
    c(1L, NA_integer_)
  )
  expect_equal(
    HLA_mismatch_number(recip_multi, donor_multi, c("HLA-A", "HLA-B"), "HvG"),
    c("HLA-A=1, HLA-B=1", NA)
  )
})

test_that("HLA_match_number returns NA for NA pairs", {
  # Without the input-side NA mask, the NA pair would read as 2 matches.
  expect_equal(
    HLA_match_number(recip_single, donor_single, "HLA-A", "HvG"),
    c(1, NA)
  )
  expect_equal(
    HLA_match_number(recip_multi, donor_multi, c("HLA-A", "HLA-B"), "HvG"),
    c("HLA-A=1, HLA-B=1", NA)
  )
})

test_that("HLA_mismatch_logical returns NA, not FALSE, for NA pairs", {
  expect_equal(
    HLA_mismatch_logical(recip_single, donor_single, "HLA-A", "HvG"),
    c(TRUE, NA)
  )
  expect_equal(
    HLA_mismatch_logical(recip_single, donor_single, "HLA-A", "bidirectional"),
    c(TRUE, NA)
  )
  expect_equal(
    HLA_mismatch_logical(recip_multi, donor_multi, c("HLA-A", "HLA-B"), "HvG"),
    c("HLA-A=TRUE, HLA-B=TRUE", NA)
  )
})

test_that("HLA_match_summary_HCT returns NA for NA pairs in both scopes", {
  gl_8 <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*01:02+HLA-C*03:04^HLA-DRB1*04:01+HLA-DRB1*07:01"
  recip <- c(gl_8, NA)
  donor <- c(gl_8, gl_8)
  expect_equal(
    HLA_match_summary_HCT(recip, donor, match_grade = "Xof8"),
    c(8L, NA_integer_)
  )
  # Genotype-scope bidirectional takes a separate code path (per-direction
  # totals then pmax), so it is pinned separately.
  expect_equal(
    HLA_match_summary_HCT(recip, donor, direction = "bidirectional", match_grade = "Xof8", scope = "genotype"),
    c(8L, NA_integer_)
  )
})
