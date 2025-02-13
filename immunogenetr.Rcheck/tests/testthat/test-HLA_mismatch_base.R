library(testthat)
library(stringr)
library(dplyr)

test_that("HLA_mismatch_base correctly identifies mismatches", {
  GL_string_recip <- "HLA-A*02:01+HLA-A*03:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*04:01+HLA-DRB1*13:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  expect_equal(result_HvG, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  result_GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  expect_equal(result_GvH, "HLA-A=HLA-A*02:01, HLA-B=HLA-B*08:01, HLA-DRB1=HLA-DRB1*07:01")

  result_single_locus <- HLA_mismatch_base(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus, "HLA-A*01:01")

  result_HvG_homo1 <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG", homozygous_count = 1)
  expect_equal(result_HvG_homo1, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  expect_error(HLA_mismatch_base(c(GL_string_recip, GL_string_recip), GL_string_donor, loci, direction = "HvG"),
               "Recipient and donor GL strings must be of equal length")
})
