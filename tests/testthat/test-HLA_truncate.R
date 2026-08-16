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

test_that("HLA_truncate is vectorized and propagates NA", {
  expect_equal(
    HLA_truncate(c("HLA-A*01:01:01:01", NA, "HLA-B*07:02:01")),
    c("HLA-A*01:01", NA, "HLA-B*07:02")
  )
  expect_equal(HLA_truncate(NA), NA_character_)
})

test_that("HLA_truncate passes through serologic values and preserves lowercase suffixes", {
  # Serologic names have no fields to truncate and must survive unchanged.
  expect_equal(HLA_truncate("B27"), "B27")
  # HLA_validate emits lowercase suffixes; keep_suffix must retain them as-is.
  expect_equal(HLA_truncate("HLA-A*01:01:01:02n"), "HLA-A*01:01n")
  # The G group letter is dropped unless keep_G_P_group = TRUE (the truncated
  # name no longer designates the G group's allele set).
  expect_equal(HLA_truncate("HLA-DRB1*04:01:01G"), "HLA-DRB1*04:01")
})

test_that("HLA_truncate round-trips the ~ and | delimiters and deduplicates gene copies", {
  expect_equal(
    HLA_truncate("HLA-A*01:01:01~HLA-B*08:01:01"),
    "HLA-A*01:01~HLA-B*08:01"
  )
  expect_equal(
    HLA_truncate("HLA-A*01:01:01+HLA-A*02:01:01|HLA-A*01:01:01+HLA-A*03:01:01"),
    "HLA-A*01:01+HLA-A*02:01|HLA-A*01:01+HLA-A*03:01"
  )
  # remove_duplicates operates at every level of the GL String hierarchy,
  # including gene copies: a genotype heterozygous only at the third field
  # collapses to a single copy — the package's homozygous representation,
  # which the matching functions re-expand per homozygous_count.
  expect_equal(
    HLA_truncate("HLA-A*02:01:01+HLA-A*02:01:02", remove_duplicates = TRUE),
    "HLA-A*02:01"
  )
})
