library(testthat)
library(stringr)

test_that("HLA_prefix_remove correctly removes prefixes", {
  result_single <- HLA_prefix_remove("HLA-A2")
  expect_equal(result_single, "2")

  result_multiple <- HLA_prefix_remove(c("HLA-A*02:01", "HLA-B*07:02", "HLA-Cw6"))
  expect_equal(result_multiple, c("02:01", "07:02", "6"))

  result_no_prefix <- HLA_prefix_remove("A*02:01")
  expect_equal(result_no_prefix, "02:01")

  result_locus_only <- HLA_prefix_remove("HLA-DRB1*15:01")
  expect_equal(result_locus_only, "15:01")

  result_mixed <- HLA_prefix_remove(c("A66", "B27", "HLA-Cw4", "HLA-DR52"))
  expect_equal(result_mixed, c("66", "27", "4", "52"))

  result_empty <- HLA_prefix_remove("")
  expect_equal(result_empty, "")

  result_na <- HLA_prefix_remove(NA)
  expect_true(is.na(result_na))

  result_special_chars <- HLA_prefix_remove("HLA-**01:01")
  expect_equal(result_special_chars, "*01:01")
})
