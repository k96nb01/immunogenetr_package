library(testthat)
library(dplyr)
library(tidyr)
library(stringr)

test_that("ambiguity_table_to_GLstring correctly converts data frame to GL string", {
  data <- tribble(
    ~value,                  ~entry, ~possible_gene_location, ~locus, ~genotype_ambiguity, ~genotype, ~haplotype, ~allele,
    "HLA-A*01:01:01:01",     1,      1,                       1,      1,                   1,         1,          1,
    "HLA-A*01:02",           1,      1,                       1,      1,                   1,         1,          2,
    "HLA-A*01:03",           1,      1,                       1,      1,                   1,         1,          3,
    "HLA-A*01:95",           1,      1,                       1,      1,                   1,         1,          4,
    "HLA-A*24:02:01:01",     1,      1,                       1,      1,                   2,         1,          1,
    "HLA-A*01:01:01:01",     1,      1,                       1,      2,                   1,         1,          1,
    "HLA-A*01:03",           1,      1,                       1,      2,                   1,         1,          2,
    "HLA-A*24:03:01:01",     1,      1,                       1,      2,                   2,         1,          1,
    "HLA-B*07:01:01",        1,      1,                       2,      1,                   1,         1,          1,
    "B*15:01:01",            1,      1,                       2,      1,                   2,         1,          1,
    "B*15:02:01",            1,      1,                       2,      1,                   2,         1,          2,
    "B*07:03",               1,      1,                       2,      2,                   1,         1,          1,
    "B*15:99:01",            1,      1,                       2,      2,                   2,         1,          1,
    "HLA-DRB1*03:01:02",     1,      1,                       3,      1,                   1,         1,          1,
    "HLA-DRB5*01:01:01",     1,      1,                       3,      1,                   1,         2,          1,
    "HLA-KIR2DL5A*0010101",  1,      1,                       3,      1,                   2,         1,          1,
    "HLA-KIR2DL5A*0010201",  1,      1,                       3,      1,                   3,         1,          1,
    "HLA-KIR2DL5B*0010201",  1,      2,                       1,      1,                   1,         1,          1,
    "HLA-KIR2DL5B*0010301",  1,      2,                       1,      1,                   2,         1,          1
  )

  result <- ambiguity_table_to_GLstring(data)
  expected <- "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A*01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01^HLA-B*07:01:01+B*15:01:01/B*15:02:01|B*07:03+B*15:99:01^HLA-DRB1*03:01:02~HLA-DRB5*01:01:01+HLA-KIR2DL5A*0010101+HLA-KIR2DL5A*0010201?HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"

  expect_equal(result, expected)
})
