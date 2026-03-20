library(testthat)
library(dplyr)
library(stringr)
library(xml2)
library(tibble)
library(purrr)
library(tidyr)

test_that("read_HML correctly extracts GL strings from HML_1.hml", {
  # Load the first test HML file bundled with the package.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")

  if (file.exists(HML_1)) {
    result <- read_HML(HML_1)

    # Should return a tibble.
    expect_s3_class(result, "tbl_df")
    # Should have the expected columns.
    expect_true("sampleID" %in% colnames(result))
    expect_true("GL_string" %in% colnames(result))
    # Should extract rows.
    expect_gt(nrow(result), 0)
    # All GL strings should contain "HLA-" prefix.
    expect_true(all(str_detect(result$GL_string, "HLA-")))
    # HML_1 has 5 samples.
    expect_equal(nrow(result), 5)
    # Sample IDs should be present and non-NA.
    expect_false(any(is.na(result$sampleID)))
  } else {
    skip("HML_1.hml test file does not exist.")
  }
})

test_that("read_HML correctly extracts GL strings from hml_2.hml", {
  # Load the second test HML file with a slightly different format.
  HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

  if (file.exists(HML_2)) {
    result <- read_HML(HML_2)

    # Should return a tibble with the same structure.
    expect_s3_class(result, "tbl_df")
    expect_true(all(c("sampleID", "GL_string") %in% colnames(result)))
    expect_gt(nrow(result), 0)
    # hml_2 also has 5 samples.
    expect_equal(nrow(result), 5)
    # All GL strings should contain "HLA-".
    expect_true(all(str_detect(result$GL_string, "HLA-")))
  } else {
    skip("hml_2.hml test file does not exist.")
  }
})

test_that("read_HML produces valid GL strings with locus separators", {
  # Verify that the output GL strings have proper "^" locus separators.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")

  if (file.exists(HML_1)) {
    result <- read_HML(HML_1)

    # Each GL string should contain "^" separating loci.
    expect_true(all(str_detect(result$GL_string, "\\^")))
    # Each GL string should contain "+" separating gene copies.
    expect_true(all(str_detect(result$GL_string, "\\+")))
  } else {
    skip("HML_1.hml test file does not exist.")
  }
})

test_that("read_HML results are consistent between both HML files", {
  # Both HML files represent the same 5 samples; GL strings should align.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")
  HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

  if (file.exists(HML_1) && file.exists(HML_2)) {
    result_1 <- read_HML(HML_1)
    result_2 <- read_HML(HML_2)

    # Both should have the same number of samples.
    expect_equal(nrow(result_1), nrow(result_2))
  } else {
    skip("HML test files do not exist.")
  }
})

test_that("read_HML errors on non-existent file", {
  # Should produce an error for a file that doesn't exist.
  expect_error(read_HML("nonexistent_file.hml"))
})

test_that("read_HML errors on invalid XML", {
  # Create a temporary file with invalid XML content.
  bad_file <- tempfile(fileext = ".hml")
  writeLines("This is not valid XML content <><>", bad_file)

  expect_error(read_HML(bad_file))
  # Clean up.
  unlink(bad_file)
})

test_that("read_HML validates input", {
  # NULL input should error.
  expect_error(read_HML(NULL))
  # Numeric input should error.
  expect_error(read_HML(123))
})
