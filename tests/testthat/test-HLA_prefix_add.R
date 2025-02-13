library(testthat)
library(stringr)

test_that("HLA_prefix_add correctly adds prefixes", {
  result_single <- HLA_prefix_add("01:01", "HLA-A*")
  expect_equal(result_single, "HLA-A*01:01")

  result_multiple <- HLA_prefix_add(c("02:01", "03:02", "11:01"), "HLA-B*")
  expect_equal(result_multiple, c("HLA-B*02:01", "HLA-B*03:02", "HLA-B*11:01"))

  result_numeric <- HLA_prefix_add("2", "HLA-A")
  expect_equal(result_numeric, "HLA-A2")

  result_empty <- HLA_prefix_add("", "HLA-C*")
  expect_equal(result_empty, "HLA-C*")

  result_na <- HLA_prefix_add(NA, "HLA-")
  expect_true(is.na(result_na))

  result_default <- HLA_prefix_add("DRB1*04:01")
  expect_equal(result_default, "HLA-DRB1*04:01")

  result_no_prefix <- HLA_prefix_add("DQB1*06:02", "")
  expect_equal(result_no_prefix, "DQB1*06:02")

  result_special_chars <- HLA_prefix_add("**01:01", "HLA-")
  expect_equal(result_special_chars, "HLA-**01:01")
})
