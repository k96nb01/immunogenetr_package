library(testthat)
library(dplyr)
library(stringr)
library(xml2)
library(tibble)
library(purrr)
library(tidyr)

test_that("read_HML correctly extracts GL strings from HML files", {
  test_file <- "/inst/extdata/HML_1.hml"

  if (file.exists(test_file)) {
    result <- read_HML(test_file)

    expect_s3_class(result, "tbl_df")
    expect_true("sampleID" %in% colnames(result))
    expect_true("GL_string" %in% colnames(result))
    expect_gt(nrow(result), 0)  #rows are extracted

    expect_true(any(str_detect(result$GL_string, "HLA-")))
  } else {
    skip("Test file does not exist.")
  }
})
