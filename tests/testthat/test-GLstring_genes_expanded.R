library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_genes_expanded correctly expands GL Strings into separate loci", {
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
  # Known behavior: DRB4 has a single allele (no "+") while other loci have two.
  # When unnest() expands list columns to equal lengths, the single DRB4 value
  # gets recycled to 2 rows. This is expected given the current pivot_wider + unnest
  # approach in GLstring_genes_expanded.
  expect_equal(sum(result$DRB4 == "HLA-DRB4*01:03"), 2)
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

test_that("GLstring_genes_expanded handles multi-row input with differing per-row allele counts", {
  # The v2 rewrite's headline capability: rows with different allele counts per
  # locus are expanded independently and row-bound. Row 1 contributes 2 rows per
  # locus; row 2 has a single HLA-A allele that recycles against its two HLA-B
  # alleles. Pins the exact output so a future rewrite can't change row order
  # or per-row expansion semantics.
  table <- data.frame(
    GL_string = c(
      "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01",
      "HLA-A*03:01^HLA-B*15:01+HLA-B*44:02"
    ),
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes_expanded(table, "GL_string")

  expect_equal(
    result,
    tibble::tibble(
      A = c("HLA-A*01:01", "HLA-A*02:01", "HLA-A*03:01", "HLA-A*03:01"),
      B = c("HLA-B*07:02", "HLA-B*08:01", "HLA-B*15:01", "HLA-B*44:02")
    )
  )
})

test_that("GLstring_genes_expanded recycles a length-1 locus to the row's max allele count", {
  # Pins the intentional recycling rule: a locus with one allele in a row is
  # duplicated into every expanded row for that input row (matches the v1
  # unnest behavior the package treats as intended).
  table <- data.frame(
    GL_string = "HLA-A*24:02+HLA-A*29:02^HLA-B*44:03",
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes_expanded(table, "GL_string")

  expect_equal(
    result,
    tibble::tibble(
      A = c("HLA-A*24:02", "HLA-A*29:02"),
      B = c("HLA-B*44:03", "HLA-B*44:03")
    )
  )
})

test_that("GLstring_genes_expanded fills NA for a locus absent from a row", {
  # A locus present in one row but missing from another must yield NA (not a
  # recycled value or dropped rows) in the rows that lack it. Pins the exact
  # NA fill from bind_rows.
  table <- data.frame(
    GL_string = c(
      "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01",
      "HLA-A*03:01+HLA-A*11:01"
    ),
    stringsAsFactors = FALSE
  )

  result <- GLstring_genes_expanded(table, "GL_string")

  expect_equal(
    result,
    tibble::tibble(
      A = c("HLA-A*01:01", "HLA-A*02:01", "HLA-A*03:01", "HLA-A*11:01"),
      B = c("HLA-B*07:02", "HLA-B*08:01", NA, NA)
    )
  )
})
