library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("ambiguity_table_to_GLstring correctly converts data frame to GL string", {
  data <- data.frame(
    value = c(
      "HLA-A*01:01:01:01", "HLA-A*01:02", "HLA-A*01:03", "HLA-A*01:95",
      "HLA-A*24:02:01:01", "HLA-A*01:01:01:01", "HLA-A*01:03",
      "HLA-A*24:03:01:01", "HLA-B*07:01:01", "B*15:01:01"),
    possible_gene_location = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
    locus = c("HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A",
              "HLA-A", "HLA-B", "HLA-B"),
    genotype_ambiguity = c(1, 1, 1, 1, 1, 2, 2, 2, 1, 1),
    genotype = c(1, 1, 1, 1, 2, 1, 1, 2, 1, 2),
    haplotype = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
    entry = c(1, 2, 3, 4, 1, 1, 2, 1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- ambiguity_table_to_GLstring(data)
  expected <- "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A*01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01^HLA-B*07:01:01+B*15:01:01"

  result_sorted <- strsplit(result, "[\\^|+]", perl = TRUE)[[1]] |> sort()
  expected_sorted <- strsplit(expected, "[\\^|+]", perl = TRUE)[[1]] |> sort()

  # expect_equal(result_sorted, expected_sorted)
})
