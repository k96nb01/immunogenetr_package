library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_mismatch_logical correctly identifies presence of mismatches", {
  GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
  GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-DRB3*03:01"

  result_HvG <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "HvG")
  expect_true(result_HvG)

  result_GvH <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "GvH")
  expect_true(result_GvH)

  result_DRB3 <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-DRB3/4/5", direction = "HvG")
  expect_false(result_DRB3)

  result_bidirectional <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "bidirectional")
  expect_true(result_bidirectional)

  result_multi_loci <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_match(result_multi_loci, "HLA-A=TRUE")
  expect_match(result_multi_loci, "HLA-DRB3/4/5=FALSE")

  result_SOT <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "SOT")
  expect_true(result_SOT)

  GL_string_donor_same <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
  result_no_mismatch <- HLA_mismatch_logical(GL_string_recip, GL_string_donor_same, loci = c("HLA-A", "HLA-DRB3/4/5"), direction = "bidirectional")
  expect_match(result_no_mismatch, "HLA-A=FALSE")
  expect_match(result_no_mismatch, "HLA-DRB3/4/5=FALSE")
})


# --- Input validation tests ---

test_that("HLA_mismatch_logical rejects NULL inputs", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(NULL, gl, "HLA-A", "HvG"), "GL_string_recip")
  expect_error(HLA_mismatch_logical(gl, NULL, "HLA-A", "HvG"), "GL_string_donor")
  expect_error(HLA_mismatch_logical(gl, gl, NULL, "HvG"), "loci")
})

test_that("HLA_mismatch_logical rejects non-character GL strings", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(123, gl, "HLA-A", "HvG"), "must be a character")
})

test_that("HLA_mismatch_logical rejects invalid direction", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(gl, gl, "HLA-A", "invalid"))
})

test_that("HLA_mismatch_logical returns FALSE for perfect match", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  # Single locus
  expect_false(HLA_mismatch_logical(gl, gl, "HLA-A", "bidirectional"))
  # Multiple loci
  result <- HLA_mismatch_logical(gl, gl, c("HLA-A", "HLA-B"), "bidirectional")
  expect_match(result, "HLA-A=FALSE")
  expect_match(result, "HLA-B=FALSE")
})

test_that("HLA_mismatch_logical works with vectorized inputs", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*03:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  # Single locus: should return logical vector of length 2
  result <- HLA_mismatch_logical(recip, donor, "HLA-A", "HvG")
  expect_length(result, 2)
  expect_true(result[1])
  expect_false(result[2])
})
