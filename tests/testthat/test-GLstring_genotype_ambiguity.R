library(testthat)
library(dplyr)
library(stringr)

test_that("GLstring_genotype_ambiguity correctly retains the first genotype ambiguity", {
  HLA_type <- data.frame(
    sample = c("sample1", "sample2"),
    HLA_A = c(
      "A*01:01+A*68:01|A*01:02+A*68:55|A*01:99+A*68:66",
      "A*02:01+A*03:01|A*02:02+A*03:03"
    ),
    HLA_B = c(
      "B*07:02+B*58:01|B*07:03+B*58:09",
      "B*08:01+B*15:01|B*08:02+B*15:17"
    ),
    stringsAsFactors = FALSE
  )

  result <- GLstring_genotype_ambiguity(HLA_type, columns = c("HLA_A", "HLA_B"))

  expect_s3_class(result, "data.frame")
  expect_equal(result$HLA_A[1], "A*01:01+A*68:01")
  expect_equal(result$HLA_A[2], "A*02:01+A*03:01")
  expect_equal(result$HLA_B[1], "B*07:02+B*58:01")
  expect_equal(result$HLA_B[2], "B*08:01+B*15:01")
})

test_that("GLstring_genotype_ambiguity errors when genes have not been separated", {
  # Create a data frame with a full GL string that still contains "^" (gene separator),
  # indicating genes haven't been split with GLstring_genes() first.
  unseparated <- data.frame(
    GL_string = "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01",
    stringsAsFactors = FALSE
  )

  # Should error because "^" is still present in the GL string

  expect_error(
    GLstring_genotype_ambiguity(unseparated, columns = "GL_string"),
    "Genes must be separated"
  )
})

test_that("GLstring_genotype_ambiguity keeps ambiguities when keep_ambiguities = TRUE", {
  # Data with multiple genotype ambiguities separated by "|"
  HLA_type <- data.frame(
    sample = c("sample1"),
    HLA_A = c("A*01:01+A*68:01|A*01:02+A*68:55|A*01:99+A*68:66"),
    stringsAsFactors = FALSE
  )

  # With keep_ambiguities = TRUE, should create an "_genotype_ambiguity" column
  result <- GLstring_genotype_ambiguity(HLA_type, columns = "HLA_A", keep_ambiguities = TRUE)

  # First genotype ambiguity should be in the original column

  expect_equal(result$HLA_A, "A*01:01+A*68:01")
  # Remaining ambiguities should be in the new column

  expect_equal(result$HLA_A_genotype_ambiguity, "A*01:02+A*68:55|A*01:99+A*68:66")
})

test_that("GLstring_genotype_ambiguity returns NA for ambiguity column when no ambiguity exists", {
  # Data with no genotype ambiguity (no "|" in the GL string)
  no_ambiguity <- data.frame(
    HLA_A = "A*01:01+A*68:01",
    stringsAsFactors = FALSE
  )

  # With keep_ambiguities = TRUE, ambiguity column should be NA
  result <- GLstring_genotype_ambiguity(no_ambiguity, columns = "HLA_A", keep_ambiguities = TRUE)

  expect_equal(result$HLA_A, "A*01:01+A*68:01")
  expect_true(is.na(result$HLA_A_genotype_ambiguity))
})

test_that("GLstring_genotype_ambiguity validates inputs", {
  # Non-data-frame input should error
  expect_error(
    GLstring_genotype_ambiguity("not a data frame", columns = "col1")
  )

  # Non-logical keep_ambiguities should error
  HLA_type <- data.frame(HLA_A = "A*01:01+A*02:01", stringsAsFactors = FALSE)
  expect_error(
    GLstring_genotype_ambiguity(HLA_type, columns = "HLA_A", keep_ambiguities = "yes")
  )
})
