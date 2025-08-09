library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_mismatch_alleles correctly identifies mismatched alleles", {
  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*13:01+HLA-DRB1*14:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  result_GvH <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  result_bidirectional <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, loci, direction = "bidirectional")
  result_SOT <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, loci, direction = "SOT")

  expect_equal(result_HvG, "HLA-A=HLA-A*03:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*14:01")
  expect_equal(result_GvH, "HLA-A=HLA-A*02:01, HLA-B=HLA-B*08:01, HLA-DRB1=HLA-DRB1*15:01")
  expect_equal(result_SOT, "HLA-A=HLA-A*03:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*14:01")
  expect_equal(result_bidirectional, "HvG;HLA-A=HLA-A*03:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*14:01<>GvH;HLA-A=HLA-A*02:01, HLA-B=HLA-B*08:01, HLA-DRB1=HLA-DRB1*15:01")

  result_single_locus <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus, "HLA-A*03:01")

  result_homozygous_1 <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 1)
  expect_equal(result_homozygous_1, "HLA-B*44:02")

  result_homozygous_2 <- HLA_mismatch_alleles(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 2)
  expect_equal(result_homozygous_2, "HLA-B*44:02")

  expect_error(HLA_mismatch_alleles(GL_string_recip, GL_string_donor, loci, direction = "invalid"))
})
