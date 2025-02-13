library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_genes correctly processes GL strings", {
  table <- data.frame(
    GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02",
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes(table, "GL_string")

  expect_s3_class(result, "data.frame")
  expect_true(all(c("HLA_A", "HLA_C", "HLA_B") %in% colnames(result)))
  expect_true("HLA-A*29:02+HLA-A*30:02" %in% result$HLA_A)
  expect_true("HLA-C*06:02+HLA-C*07:01" %in% result$HLA_C)
  expect_true("HLA-B*08:01+HLA-B*13:02" %in% result$HLA_B)
})
