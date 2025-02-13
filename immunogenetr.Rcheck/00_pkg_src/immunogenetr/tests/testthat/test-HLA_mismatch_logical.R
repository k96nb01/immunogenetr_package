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
