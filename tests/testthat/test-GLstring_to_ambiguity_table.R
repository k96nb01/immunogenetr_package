library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("GLstring_to_ambiguity_table creates an ambiguity table correctly", {
  GL_string <- "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A*01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01^HLA-B*07:01:01+B*15:01:01/B*15:02:01|B*07:03+B*15:99:01^HLA-DRB1*03:01:02~HLA-DRB5*01:01:01+HLA-KIR2DL5A*0010101+HLA-KIR2DL5A*0010201?HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"
  result <- GLstring_to_ambiguity_table(GL_string)

  expect_s3_class(result, "tbl_df")
  expect_true("locus" %in% colnames(result))
  expect_true("allele" %in% colnames(result))
  expect_gt(nrow(result), 0)
})
