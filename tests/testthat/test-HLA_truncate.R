library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_truncate correctly truncates HLA alleles", {
  allele_4_field <- "HLA-A*01:01:01:02N"
  allele_3_field <- "HLA-B*07:02:01"
  allele_2_field <- "HLA-C*06:02"
  allele_g_group <- "HLA-DRB1*04:01:01G"

  expect_equal(HLA_truncate(allele_4_field), "HLA-A*01:01N")
  expect_equal(HLA_truncate(allele_3_field, fields = 3), "HLA-B*07:02:01")
  expect_equal(HLA_truncate(allele_2_field, fields = 1), "HLA-C*06")
  expect_equal(HLA_truncate(allele_g_group, keep_G_P_group = TRUE), "HLA-DRB1*04:01G")
  expect_equal(HLA_truncate(allele_4_field, keep_suffix = FALSE), "HLA-A*01:01")
  expect_equal(HLA_truncate(allele_4_field, fields = 1, keep_suffix = FALSE), "HLA-A*01")

  gl_string <- "HLA-A*02:01:01:01+HLA-A*68:01:01^HLA-B*07:02+HLA-B*44:02:01^HLA-DRB1*04:01:01+HLA-DRB1*13:01"
  expected_truncated <- "HLA-A*02:01+HLA-A*68:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*04:01+HLA-DRB1*13:01"
  expect_equal(HLA_truncate(gl_string), expected_truncated)

  GL_string_duplicates <- "HLA-A*02:01:03/HLA-A*02:01:06"
  expect_equal(HLA_truncate(GL_string_duplicates, remove_duplicates = FALSE), "HLA-A*02:01/HLA-A*02:01")
  expect_equal(HLA_truncate(GL_string_duplicates, remove_duplicates = TRUE), "HLA-A*02:01")
})
