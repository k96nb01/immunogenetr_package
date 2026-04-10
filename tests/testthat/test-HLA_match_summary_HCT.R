library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_match_summary_HCT correctly calculates match summary for HCT", {
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

  result_Xof8_HvG <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof8")
  result_Xof8_GvH <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof8")
  result_Xof8_bidirectional <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof8")

  expect_type(result_Xof8_HvG, "integer")
  expect_type(result_Xof8_GvH, "integer")
  expect_type(result_Xof8_bidirectional, "integer")

  expect_equal(result_Xof8_HvG, 4)
  expect_equal(result_Xof8_GvH, 5)
  expect_equal(result_Xof8_bidirectional, 4)

  result_Xof10_HvG <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof10")
  result_Xof10_GvH <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof10")
  result_Xof10_bidirectional <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof10")

  expect_type(result_Xof10_HvG, "integer")
  expect_type(result_Xof10_GvH, "integer")
  expect_type(result_Xof10_bidirectional, "integer")

  expect_equal(result_Xof10_HvG, 6)
  expect_equal(result_Xof10_GvH, 7)
  expect_equal(result_Xof10_bidirectional, 6)

  perfect_match <- HLA_match_summary_HCT(GL_string_recip, GL_string_recip, direction = "bidirectional", match_grade = "Xof10")
  expect_equal(perfect_match, 10)

  GL_string_mismatch <- "HLA-A*24:01^HLA-C*05:01+HLA-C*08:01^HLA-B*51:01+HLA-B*52:01^HLA-DRB1*15:01+HLA-DRB1*16:01^HLA-DQB1*05:01+HLA-DQB1*06:01"
  mismatch_result <- HLA_match_summary_HCT(GL_string_recip, GL_string_mismatch, direction = "bidirectional", match_grade = "Xof10")
  expect_equal(mismatch_result, 0)

  expect_error(HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "invalid"))
})


# --- Input validation tests ---

test_that("HLA_match_summary_HCT rejects NULL inputs", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  expect_error(HLA_match_summary_HCT(NULL, gl, match_grade = "Xof8"), "GL_string_recip")
  expect_error(HLA_match_summary_HCT(gl, NULL, match_grade = "Xof8"), "GL_string_donor")
})

test_that("HLA_match_summary_HCT rejects non-character GL strings", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  expect_error(HLA_match_summary_HCT(123, gl, match_grade = "Xof8"), "must be a character")
})

test_that("HLA_match_summary_HCT rejects invalid match_grade", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  expect_error(HLA_match_summary_HCT(gl, gl, match_grade = "Xof6"))
})

test_that("HLA_match_summary_HCT returns 8 for perfect Xof8 match", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  result <- HLA_match_summary_HCT(gl, gl, direction = "bidirectional", match_grade = "Xof8")
  expect_equal(result, 8)
})

# --- Scope parameter tests ---

test_that("HLA_match_summary_HCT scope='locus' returns same results as default", {
  # Locus scope should match default behavior exactly.
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

  # Explicitly setting scope = "locus" should match not setting it at all
  expect_equal(
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof8", scope = "locus"),
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof8")
  )
  expect_equal(
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof10", scope = "locus"),
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof10")
  )
})

test_that("HLA_match_summary_HCT scope='genotype' calculates max of GvH and HvG totals", {
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

  # Genotype scope with bidirectional should return max of GvH and HvG totals
  # GvH Xof8 = 5, HvG Xof8 = 4, so genotype bidirectional Xof8 = max(5, 4) = 5
  result_Xof8_genotype <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
    direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
  )
  expect_type(result_Xof8_genotype, "integer")
  expect_equal(result_Xof8_genotype, 5)

  # GvH Xof10 = 7, HvG Xof10 = 6, so genotype bidirectional Xof10 = max(7, 6) = 7
  result_Xof10_genotype <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
    direction = "bidirectional", match_grade = "Xof10", scope = "genotype"
  )
  expect_type(result_Xof10_genotype, "integer")
  expect_equal(result_Xof10_genotype, 7)
})

test_that("HLA_match_summary_HCT scope='genotype' is >= scope='locus' for bidirectional", {
  # Genotype scope should always be >= locus scope for bidirectional matching,
  # since locus takes the per-locus minimum before summing.
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

  locus_result <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
    direction = "bidirectional", match_grade = "Xof8", scope = "locus"
  )
  genotype_result <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
    direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
  )
  expect_true(genotype_result >= locus_result)
})

test_that("HLA_match_summary_HCT scope='genotype' with non-bidirectional direction is ignored", {
  # When direction is not "bidirectional", scope should not affect the result.
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"

  # GvH results should be identical regardless of scope
  expect_equal(
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof8", scope = "genotype"),
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof8", scope = "locus")
  )
  # HvG results should be identical regardless of scope
  expect_equal(
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof8", scope = "genotype"),
    HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof8", scope = "locus")
  )
})

test_that("HLA_match_summary_HCT scope='genotype' returns 7 for prompt example data", {
  # This test uses the exact data from the development prompt.
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"

  result <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
    direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
  )
  expect_equal(result, 7)
})

test_that("HLA_match_summary_HCT scope='genotype' returns perfect score for identical genotypes", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  # Perfect match: GvH = 8, HvG = 8, max(8, 8) = 8
  result <- HLA_match_summary_HCT(gl, gl, direction = "bidirectional", match_grade = "Xof8", scope = "genotype")
  expect_equal(result, 8)
})

test_that("HLA_match_summary_HCT scope='genotype' works with vectorized inputs", {
  recip <- c(
    "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  donor <- c(
    "HLA-A*02:01+HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  result <- HLA_match_summary_HCT(recip, donor,
    direction = "bidirectional", match_grade = "Xof8", scope = "genotype"
  )
  expect_length(result, 2)
  # First pair should return 7 (from prompt example)
  expect_equal(result[1], 7)
  # Second pair is a perfect match
  expect_equal(result[2], 8)
})

test_that("HLA_match_summary_HCT rejects invalid scope", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  expect_error(HLA_match_summary_HCT(gl, gl, match_grade = "Xof8", scope = "invalid"))
})


test_that("HLA_match_summary_HCT works with vectorized inputs", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01^HLA-C*01:02+HLA-C*02:02^HLA-DRB1*11:01+HLA-DRB1*13:01"
  )
  result <- HLA_match_summary_HCT(recip, donor, direction = "bidirectional", match_grade = "Xof8")
  expect_length(result, 2)
  # First pair is a perfect match
  expect_equal(result[1], 8)
  # Second pair is a complete mismatch
  expect_equal(result[2], 0)
})

test_that("HLA_match_summary_HCT works with vectorized inputs for GvH direction", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01^HLA-C*01:02+HLA-C*02:02^HLA-DRB1*11:01+HLA-DRB1*13:01"
  )
  result <- HLA_match_summary_HCT(recip, donor, direction = "GvH", match_grade = "Xof8")
  expect_length(result, 2)
  # First pair is a perfect match
  expect_equal(result[1], 8)
  # Second pair is a complete mismatch
  expect_equal(result[2], 0)
})

test_that("HLA_match_summary_HCT works with vectorized inputs for HvG direction", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01^HLA-C*01:02+HLA-C*02:02^HLA-DRB1*11:01+HLA-DRB1*13:01"
  )
  result <- HLA_match_summary_HCT(recip, donor, direction = "HvG", match_grade = "Xof8")
  expect_length(result, 2)
  # First pair is a perfect match
  expect_equal(result[1], 8)
  # Second pair is a complete mismatch
  expect_equal(result[2], 0)
})

test_that("HLA_match_summary_HCT works with vectorized inputs and explicit scope='locus'", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-C*03:04+HLA-C*07:01^HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01^HLA-C*01:02+HLA-C*02:02^HLA-DRB1*11:01+HLA-DRB1*13:01"
  )
  # Explicit scope = "locus" should match the default behavior
  result_locus <- HLA_match_summary_HCT(recip, donor, direction = "bidirectional", match_grade = "Xof8", scope = "locus")
  result_default <- HLA_match_summary_HCT(recip, donor, direction = "bidirectional", match_grade = "Xof8")
  expect_equal(result_locus, result_default)
  expect_length(result_locus, 2)
  expect_equal(result_locus[1], 8)
  expect_equal(result_locus[2], 0)
})
