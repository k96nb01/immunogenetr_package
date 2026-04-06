library(testthat)
library(immunogenetr)
library(dplyr)

test_that("HLA_column_repair() returns a data frame", {
  # Set up test data with WHO-style column names including asterisks.
  output_table <- HLA_column_repair(
    tibble(
      "HLA-A*" = c("01:01", "02:01"),
      "HLA-B*" = c("07:02", "08:01"),
      "HLA-C*" = c("03:04", "04:01")
    )
  )
  expect_s3_class(output_table, "data.frame")
})

test_that("HLA_column_repair() converts WHO format to tidyverse format", {
  # Test data with WHO-style dash and asterisk in column names.
  who_data <- tibble(
    "HLA-A*" = c("01:01", "02:01"),
    "HLA-B*" = c("07:02", "08:01"),
    "HLA-DRB1*" = c("03:01", "04:01")
  )

  # Default format is "tidyverse": replaces dash with underscore and removes asterisk.
  result <- HLA_column_repair(who_data, format = "tidyverse")
  expect_true(all(c("HLA_A", "HLA_B", "HLA_DRB1") %in% colnames(result)))
  # Verify no dashes or asterisks remain in HLA column names.
  hla_cols <- grep("^HLA", colnames(result), value = TRUE)
  expect_false(any(grepl("-", hla_cols)))
  expect_false(any(grepl("\\*", hla_cols)))
})

test_that("HLA_column_repair() converts tidyverse format to WHO format", {
  # Test data with tidyverse-style underscore column names.
  tidy_data <- tibble(
    "HLA_A" = c("01:01", "02:01"),
    "HLA_B" = c("07:02", "08:01"),
    "HLA_C" = c("03:04", "04:01")
  )

  # WHO format: replaces underscore with dash.
  result <- HLA_column_repair(tidy_data, format = "WHO")
  expect_true(all(c("HLA-A", "HLA-B", "HLA-C") %in% colnames(result)))
  # Verify no underscores in HLA column names.
  hla_cols <- grep("^HLA", colnames(result), value = TRUE)
  expect_false(any(grepl("_", hla_cols)))
})

test_that("HLA_column_repair() correctly handles the asterisk parameter", {
  # Test data without asterisks.
  tidy_data <- tibble(
    "HLA_A" = c("01:01"),
    "HLA_B" = c("07:02")
  )

  # asterisk = TRUE should add asterisk to all HLA columns.
  result_with <- HLA_column_repair(tidy_data, format = "tidyverse", asterisk = TRUE)
  expect_true(all(c("HLA_A*", "HLA_B*") %in% colnames(result_with)))

  # asterisk = FALSE (default) should not add asterisk.
  result_without <- HLA_column_repair(tidy_data, format = "tidyverse", asterisk = FALSE)
  expect_false(any(grepl("\\*", colnames(result_without))))
})

test_that("HLA_column_repair() adds asterisk in WHO format", {
  # Test combining WHO format with asterisk.
  tidy_data <- tibble(
    "HLA_A" = c("01:01"),
    "HLA_DRB1" = c("03:01")
  )

  # WHO format + asterisk should produce "HLA-A*" and "HLA-DRB1*".
  result <- HLA_column_repair(tidy_data, format = "WHO", asterisk = TRUE)
  expect_true(all(c("HLA-A*", "HLA-DRB1*") %in% colnames(result)))
})

test_that("HLA_column_repair() removes existing asterisks before optionally re-adding", {
  # Test data that already has asterisks.
  who_data <- tibble(
    "HLA-A*" = c("01:01"),
    "HLA-B*" = c("07:02")
  )

  # tidyverse with asterisk = FALSE: asterisk should be removed.
  result_no_ast <- HLA_column_repair(who_data, format = "tidyverse", asterisk = FALSE)
  expect_true(all(c("HLA_A", "HLA_B") %in% colnames(result_no_ast)))

  # tidyverse with asterisk = TRUE: asterisk should be present.
  result_ast <- HLA_column_repair(who_data, format = "tidyverse", asterisk = TRUE)
  expect_true(all(c("HLA_A*", "HLA_B*") %in% colnames(result_ast)))
})

test_that("HLA_column_repair() preserves non-HLA columns unchanged", {
  # Data with a mix of HLA and non-HLA columns.
  mixed_data <- tibble(
    patient = c("P1", "P2"),
    "HLA-A*" = c("01:01", "02:01"),
    age = c(30, 45)
  )

  result <- HLA_column_repair(mixed_data, format = "tidyverse")
  # Non-HLA columns should be unchanged.
  expect_true("patient" %in% colnames(result))
  expect_true("age" %in% colnames(result))
  # HLA column should be converted.
  expect_true("HLA_A" %in% colnames(result))
})

test_that("HLA_column_repair() preserves data values", {
  # Verify that column renaming doesn't alter the data itself.
  who_data <- tibble(
    "HLA-A*" = c("01:01", "02:01"),
    "HLA-B*" = c("07:02", "08:01")
  )

  result <- HLA_column_repair(who_data, format = "tidyverse")
  expect_equal(result$HLA_A, c("01:01", "02:01"))
  expect_equal(result$HLA_B, c("07:02", "08:01"))
})

test_that("HLA_column_repair() errors on invalid format parameter", {
  test_data <- tibble("HLA-A*" = c("01:01"))
  # Invalid format should produce an error.
  expect_error(HLA_column_repair(test_data, format = "invalid"))
})

test_that("HLA_column_repair() validates inputs", {
  # NULL data should error.
  expect_error(HLA_column_repair(NULL))
  # Non-data-frame should error.
  expect_error(HLA_column_repair("not a data frame"))
  # Non-logical asterisk should error.
  test_data <- tibble("HLA-A" = c("01:01"))
  expect_error(HLA_column_repair(test_data, asterisk = "yes"))
})

test_that("HLA_column_repair() handles columns without HLA prefix", {
  # Data with no HLA columns; should return unchanged.
  no_hla_data <- tibble(
    patient = c("P1"),
    gene = c("TP53")
  )
  result <- HLA_column_repair(no_hla_data, format = "tidyverse")
  expect_equal(colnames(result), c("patient", "gene"))
})
