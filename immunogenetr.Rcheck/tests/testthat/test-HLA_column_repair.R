library(testthat) # load testthat package
library(immunogenetr) # load our package
library(dplyr)

# Test whether the output is a data frame
test_that("HLA_column_repair() returns a data frame", {
  output_table <- HLA_column_repair(
    HLA_type <- tibble(
      "HLA-A*" = c("01:01", "02:01"),
      "HLA-B*" = c("07:02", "08:01"),
      "HLA-C*" = c("03:04", "04:01"),
    )
  )
  expect_s3_class(output_table, "data.frame")
})
