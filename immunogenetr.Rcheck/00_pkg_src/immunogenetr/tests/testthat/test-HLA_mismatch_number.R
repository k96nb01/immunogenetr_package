library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_mismatch_number correctly calculates mismatch counts", {
  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*13:01+HLA-DRB1*14:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  result_GvH <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  result_bidirectional <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "bidirectional")
  result_SOT <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "SOT")

  expect_match(result_HvG, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_GvH, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_bidirectional, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_SOT, "HLA-A=1, HLA-B=1, HLA-DRB1=1")

  result_single_locus <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus, 1)

  result_homozygous_1 <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 1)
  expect_equal(result_homozygous_1, 1)

  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*44:02+HLA-B*44:02^HLA-DRB1*13:01+HLA-DRB1*14:01"
  result_homozygous_2 <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 2)
  expect_equal(result_homozygous_2, 2)

  GL_string_recip_match <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor_match <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  result_no_mismatch <- HLA_mismatch_number(GL_string_recip_match, GL_string_donor_match, loci, direction = "bidirectional")
  expect_match(result_no_mismatch, "HLA-A=0, HLA-B=0, HLA-DRB1=0")
})
