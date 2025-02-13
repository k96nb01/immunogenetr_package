library(testthat)
library(dplyr)

test_that("HLA_columns_to_GLstring correctly converts HLA columns into a GL string", {
  typing_table <- data.frame(
    patient = c("patient1", "patient2", "patient3"),
    mA1cd = c("A*01:01", "A*02:01", "A*03:01"),
    mA2cd = c("A*11:01", "blank", "A*26:01"),
    mB1cd = c("B*07:02", "B*08:01", "B*15:01"),
    mB2cd = c("B*44:02", "B*40:01", "-"),
    mC1cd = c("C*03:04", "C*04:01", "C*05:01"),
    mC2cd = c("C*07:01", "C*07:02", "C*08:01"),
    stringsAsFactors = FALSE
  )

  result <- HLA_columns_to_GLstring(
    typing_table,
    HLA_typing_columns = c("mA1cd", "mA2cd", "mB1cd", "mB2cd", "mC1cd", "mC2cd"),
    prefix_to_remove = "m",
    suffix_to_remove = "cd"
  )

  expect_equal(length(result), 3)
  expect_true("HLA-A*01:01+HLA-A*11:01^HLA-B*07:02+HLA-B*44:02^HLA-C*03:04+HLA-C*07:01" %in% result)
  expect_true("HLA-A*02:01^HLA-B*08:01+HLA-B*40:01^HLA-C*04:01+HLA-C*07:02" %in% result)
  expect_true("HLA-A*03:01+HLA-A*26:01^HLA-B*15:01^HLA-C*05:01+HLA-C*08:01" %in% result)
})
