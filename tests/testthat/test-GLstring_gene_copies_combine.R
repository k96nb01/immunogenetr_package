library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_gene_copies_combine correctly combines HLA gene copies", {
  HLA_type <- data.frame(
    sample = c("sample1", "sample2"),
    HLA_A1 = c("HLA-A*01:01", "HLA-A*02:01"),
    HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
    stringsAsFactors = FALSE
  )
  result <- GLstring_gene_copies_combine(HLA_type, columns = c("HLA_A1", "HLA_A2"))

  expect_s3_class(result, "data.frame")
  expect_true("HLA_A" %in% colnames(result))
  expect_equal(nrow(result), 2)

  expect_match(result$HLA_A[1], "HLA-A\\*01:01\\+HLA-A\\*01:02")
  expect_match(result$HLA_A[2], "HLA-A\\*02:01\\+HLA-A\\*02:02")
})

test_that("GLstring_gene_copies_combine handles missing values correctly", {
  HLA_type <- data.frame(
    sample = c("sample1", "sample2"),
    HLA_A1 = c("HLA-A*01:01", NA),
    HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
    stringsAsFactors = FALSE
  )

  result <- GLstring_gene_copies_combine(HLA_type, columns = c("HLA_A1", "HLA_A2"))

  expect_s3_class(result, "data.frame")
  expect_true("HLA_A" %in% colnames(result))
  expect_equal(nrow(result), 2)

  expect_match(result$HLA_A[1], "HLA-A\\*01:01\\+HLA-A\\*01:02")
  expect_match(result$HLA_A[2], "HLA-A\\*02:02")
})

test_that("GLstring_gene_copies_combine works with multiple loci", {
  HLA_type <- data.frame(
    sample = c("sample1", "sample2"),
    HLA_A1 = c("HLA-A*01:01", "HLA-A*02:01"),
    HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
    HLA_B1 = c("HLA-B*07:01", "HLA-B*08:01"),
    HLA_B2 = c("HLA-B*07:02", "HLA-B*08:02"),
    stringsAsFactors = FALSE
  )

  result <- GLstring_gene_copies_combine(HLA_type, columns = c("HLA_A1", "HLA_A2", "HLA_B1", "HLA_B2"))

  expect_s3_class(result, "data.frame")
  expect_true(all(c("HLA_A", "HLA_B") %in% colnames(result)))
  expect_equal(nrow(result), 2)

  # Check correct GL String combination for multiple loci
  expect_match(result$HLA_A[1], "HLA-A\\*01:01\\+HLA-A\\*01:02")
  expect_match(result$HLA_A[2], "HLA-A\\*02:01\\+HLA-A\\*02:02")
  expect_match(result$HLA_B[1], "HLA-B\\*07:01\\+HLA-B\\*07:02")
  expect_match(result$HLA_B[2], "HLA-B\\*08:01\\+HLA-B\\*08:02")
})

test_that("GLstring_gene_copies_combine does not pick up grouping variables", {
  df <- tibble::tibble(
    sample = c("s1", "s2"),
    grp = c("a", "b"),
    A1 = c("HLA-A*01:01", "HLA-A*03:01"),
    A2 = c("HLA-A*02:01", "HLA-A*24:02")
  )
  expect_equal(
    GLstring_gene_copies_combine(dplyr::group_by(df, grp), c(A1, A2), sample_column = sample),
    GLstring_gene_copies_combine(df, c(A1, A2), sample_column = sample)
  )
})
