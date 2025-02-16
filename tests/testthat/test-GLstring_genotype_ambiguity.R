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
