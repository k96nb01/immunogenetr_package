library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_match_number correctly calculates HLA match numbers across different scenarios", {
  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*04:01+HLA-DRB1*13:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  result_GvH <- HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  result_bidirectional <- HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "bidirectional")

  expect_match(result_HvG, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_GvH, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_bidirectional, "HLA-A=1, HLA-B=1, HLA-DRB1=1")

  perfect_match <- HLA_match_number(GL_string_recip, GL_string_recip, loci, direction = "bidirectional")
  expect_match(perfect_match, "HLA-A=2, HLA-B=2, HLA-DRB1=2")

  GL_string_mismatch <- "HLA-A*24:01+HLA-A*25:01^HLA-B*51:01+HLA-B*52:01^HLA-DRB1*15:01+HLA-DRB1*16:01"
  mismatch_result <- HLA_match_number(GL_string_recip, GL_string_mismatch, loci, direction = "bidirectional")
  expect_match(mismatch_result, "HLA-A=0, HLA-B=0, HLA-DRB1=0")

  result_A <- HLA_match_number(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  result_B <- HLA_match_number(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG")
  result_DRB1 <- HLA_match_number(GL_string_recip, GL_string_donor, "HLA-DRB1", direction = "HvG")

  expect_equal(result_A, 1)
  expect_equal(result_B, 1)
  expect_equal(result_DRB1, 1)

  expect_error(HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "invalid"))
})


# --- Input validation tests ---

test_that("HLA_match_number rejects NULL inputs", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_match_number(NULL, gl, "HLA-A", "HvG"), "GL_string_recip")
  expect_error(HLA_match_number(gl, NULL, "HLA-A", "HvG"), "GL_string_donor")
  expect_error(HLA_match_number(gl, gl, NULL, "HvG"), "loci")
})

test_that("HLA_match_number rejects non-character GL strings", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_match_number(123, gl, "HLA-A", "HvG"), "must be a character")
})

test_that("HLA_match_number returns 2 for perfect match at single locus", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  result <- HLA_match_number(gl, gl, "HLA-A", "bidirectional")
  expect_equal(result, 2)
})

test_that("HLA_match_number returns 0 for complete mismatch at single locus", {
  recip <- "HLA-A*01:01+HLA-A*02:01"
  donor <- "HLA-A*03:01+HLA-A*24:02"
  result <- HLA_match_number(recip, donor, "HLA-A", "bidirectional")
  expect_equal(result, 0)
})

test_that("HLA_match_number works with vectorized inputs", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*08:01",
    "HLA-A*03:01+HLA-A*24:02^HLA-B*15:01+HLA-B*40:01"
  )
  # Single locus: should return integer vector of length 2
  result <- HLA_match_number(recip, donor, "HLA-A", "HvG")
  expect_length(result, 2)
  expect_equal(result[1], 1)
  expect_equal(result[2], 2)

  # Multiple loci: should return character vector of length 2
  result_multi <- HLA_match_number(recip, donor, c("HLA-A", "HLA-B"), "bidirectional")
  expect_length(result_multi, 2)
  expect_match(result_multi[1], "HLA-A=1, HLA-B=2")
  expect_match(result_multi[2], "HLA-A=2, HLA-B=2")
})
