library(testthat)
library(stringr)

test_that("GLstring_regex correctly formats HLA alleles to regex patterns", {
  # Basic two-field alleles should be properly escaped with lookahead.
  expect_equal(GLstring_regex("HLA-A*02:01"), "HLA-A\\*02:01(?=(\\?|\\^|\\||\\+|\\~|/|:|$))")
  expect_equal(GLstring_regex("HLA-B*07:02"), "HLA-B\\*07:02(?=(\\?|\\^|\\||\\+|\\~|/|:|$))")
  # Multi-character locus name.
  expect_equal(GLstring_regex("HLA-DRB1*03:01"), "HLA-DRB1\\*03:01(?=(\\?|\\^|\\||\\+|\\~|/|:|$))")
})

test_that("GLstring_regex errors without HLA- prefix", {
  # Alleles without "HLA-" prefix should produce an error.
  expect_error(GLstring_regex("A*02:01"))
  expect_error(GLstring_regex("B27"))
})

test_that("GLstring_regex handles vector input", {
  # Should accept and process a vector of alleles.
  alleles <- c("HLA-A*02:01", "HLA-B*07:02", "HLA-C*04:01")
  result <- GLstring_regex(alleles)

  # Should return a vector of the same length.
  expect_length(result, 3)
  # Each element should be a valid regex string.
  expect_true(all(grepl("\\(\\?=", result)))
})

test_that("GLstring_regex produces patterns that match correctly in GL strings", {
  # Set up a GL string with multiple alleles.
  gl <- "HLA-A*02:01:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01"

  # Two-field allele should match the four-field allele (fewer fields match more).
  pattern_a <- GLstring_regex("HLA-A*02:01")
  expect_true(str_detect(gl, pattern_a))

  # Full three-field allele should also match.
  pattern_a3 <- GLstring_regex("HLA-A*02:01:01")
  expect_true(str_detect(gl, pattern_a3))

  # A non-present allele should not match.
  pattern_missing <- GLstring_regex("HLA-A*03:01")
  expect_false(str_detect(gl, pattern_missing))
})

test_that("GLstring_regex prevents partial field matching", {
  # The regex should NOT match "HLA-A*02:149:01" when searching for "HLA-A*02:14".
  gl_with_long_allele <- "HLA-A*02:149:01"
  pattern <- GLstring_regex("HLA-A*02:14")
  expect_false(str_detect(gl_with_long_allele, pattern))

  # But "HLA-A*02:14" should match itself at end of string.
  expect_true(str_detect("HLA-A*02:14", pattern))
})

test_that("GLstring_regex matches alleles at GL string boundaries", {
  # Allele at the end of a GL string (followed by $).
  gl <- "HLA-A*01:01+HLA-A*02:01"
  pattern <- GLstring_regex("HLA-A*02:01")
  expect_true(str_detect(gl, pattern))

  # Allele before a "^" locus separator.
  gl2 <- "HLA-A*02:01^HLA-B*07:02"
  expect_true(str_detect(gl2, pattern))

  # Allele before a "+" gene copy separator.
  gl3 <- "HLA-A*02:01+HLA-A*03:01"
  expect_true(str_detect(gl3, pattern))

  # Allele before a "/" allele ambiguity separator.
  gl4 <- "HLA-A*02:01/HLA-A*02:06"
  expect_true(str_detect(gl4, pattern))

  # Allele before a "|" genotype ambiguity separator.
  gl5 <- "HLA-A*02:01|HLA-A*02:01+HLA-A*03:01"
  expect_true(str_detect(gl5, pattern))
})

test_that("GLstring_regex handles high-resolution and rare loci", {
  # Four-field allele should match itself in a GL string context.
  result_4f <- GLstring_regex("HLA-A*02:01:01:01")
  expect_true(str_detect("HLA-A*02:01:01:01+HLA-A*03:01", result_4f))

  # DQA1 locus.
  result_dqa <- GLstring_regex("HLA-DQA1*05:01")
  expect_true(str_detect("HLA-DQA1*05:01+HLA-DQA1*01:02", result_dqa))

  # DPB1 locus.
  result_dpb <- GLstring_regex("HLA-DPB1*04:01")
  expect_true(str_detect("HLA-DPB1*04:01+HLA-DPB1*02:01", result_dpb))
})

test_that("GLstring_regex validates inputs", {
  # NA should still work through check_gl_string (allows NA).
  # But should error because "HLA-" is not detected in NA.
  expect_error(GLstring_regex(NA))
  # Empty string should error (no "HLA-" prefix).
  expect_error(GLstring_regex(""))
  # Mixed valid/invalid should error.
  expect_error(GLstring_regex(c("HLA-A*02:01", "A*03:01")))
})
