library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_genes correctly processes GL strings", {
  # Basic test with three loci separated by "^".
  table <- data.frame(
    GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02",
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes(table, "GL_string")

  # Should return a data frame.
  expect_s3_class(result, "data.frame")
  # Should have HLA_A, HLA_C, HLA_B columns (tidyverse-repaired names).
  expect_true(all(c("HLA_A", "HLA_C", "HLA_B") %in% colnames(result)))
  # Each locus column should contain the correct GL string fragment.
  expect_true("HLA-A*29:02+HLA-A*30:02" %in% result$HLA_A)
  expect_true("HLA-C*06:02+HLA-C*07:01" %in% result$HLA_C)
  expect_true("HLA-B*08:01+HLA-B*13:02" %in% result$HLA_B)
})

test_that("GLstring_genes handles a full HLA typing with many loci", {
  # GL string with standard HCT loci: A, B, C, DRB1, DQB1.
  gl <- paste(
    "HLA-A*02:01+HLA-A*03:01",
    "HLA-B*07:02+HLA-B*44:02",
    "HLA-C*07:02+HLA-C*05:01",
    "HLA-DRB1*15:01+HLA-DRB1*03:01",
    "HLA-DQB1*06:02+HLA-DQB1*02:01",
    sep = "^"
  )
  table <- data.frame(GL_string = gl, stringsAsFactors = FALSE)

  result <- GLstring_genes(table, "GL_string")

  # Should have all five locus columns.
  expect_true(all(c("HLA_A", "HLA_B", "HLA_C", "HLA_DRB1", "HLA_DQB1") %in% colnames(result)))
  # Verify one row of output.
  expect_equal(nrow(result), 1)
})

test_that("GLstring_genes handles multiple rows", {
  # Two patients with different typings.
  table <- data.frame(
    patient = c("P1", "P2"),
    GL_string = c(
      "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01",
      "HLA-A*03:01+HLA-A*11:01^HLA-B*15:01+HLA-B*35:01"
    ),
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes(table, "GL_string")

  # Should have two rows.
  expect_equal(nrow(result), 2)
  # Should have patient column preserved.
  expect_true("patient" %in% colnames(result))
  # Should have HLA locus columns.
  expect_true(all(c("HLA_A", "HLA_B") %in% colnames(result)))
})

test_that("GLstring_genes handles GL strings with ambiguity (slash notation)", {

  # A GL string with allele-level ambiguity using "/" delimiter.
  gl <- "HLA-A*02:01/HLA-A*02:06+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02"
  table <- data.frame(GL_string = gl, stringsAsFactors = FALSE)

  result <- GLstring_genes(table, "GL_string")

  # The ambiguity should be preserved within the HLA_A column.
  expect_true(grepl("/", result$HLA_A))
  expect_true("HLA_B" %in% colnames(result))
})

test_that("GLstring_genes handles a single-locus GL string", {
  # Only one locus, no "^" separator.
  table <- data.frame(
    GL_string = "HLA-A*01:01+HLA-A*02:01",
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes(table, "GL_string")

  expect_s3_class(result, "data.frame")
  expect_true("HLA_A" %in% colnames(result))
  expect_equal(nrow(result), 1)
})

test_that("GLstring_genes handles DRB3/4/5 loci", {
  # GL string including DRB345 loci.
  gl <- paste(
    "HLA-DRB1*04:01+HLA-DRB1*07:01",
    "HLA-DRB4*01:03+HLA-DRB4*01:01",
    sep = "^"
  )
  table <- data.frame(GL_string = gl, stringsAsFactors = FALSE)

  result <- GLstring_genes(table, "GL_string")

  expect_true("HLA_DRB1" %in% colnames(result))
  expect_true("HLA_DRB4" %in% colnames(result))
})

test_that("GLstring_genes validates inputs", {
  # NULL data should error.
  expect_error(GLstring_genes(NULL, "GL_string"))
  # Non-data-frame should error.
  expect_error(GLstring_genes("not a data frame", "GL_string"))
})
