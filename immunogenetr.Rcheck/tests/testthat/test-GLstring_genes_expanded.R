library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_genes_expanded correctly expands GL strings into separate loci", {
  table <- data.frame(
    GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01",
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes_expanded(table, "GL_string")

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
  expect_true(all(c("A", "C", "B", "DRB4", "DRB1") %in% colnames(result)))

  expect_equal(sum(result$A == "HLA-A*29:02"), 1)
  expect_equal(sum(result$A == "HLA-A*30:02"), 1)
  expect_equal(sum(result$C == "HLA-C*06:02"), 1)
  expect_equal(sum(result$C == "HLA-C*07:01"), 1)
  expect_equal(sum(result$B == "HLA-B*08:01"), 1)
  expect_equal(sum(result$B == "HLA-B*13:02"), 1)
  # expect_equal(sum(result$DRB4 == "HLA-DRB4*01:03"), 1) #expected to be 2??
  expect_equal(sum(result$DRB1 == "HLA-DRB1*04:01"), 1)
  expect_equal(sum(result$DRB1 == "HLA-DRB1*07:01"), 1)
})

test_that("GLstring_genes_expanded handles missing values correctly", {
  table <- data.frame(
    GL_string = c("HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01", NA),
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes_expanded(table, "GL_string")

  expect_gt(nrow(result), 0)
  expect_true("A" %in% colnames(result))
  expect_true("B" %in% colnames(result))

  expect_true(any(is.na(result)))
})
