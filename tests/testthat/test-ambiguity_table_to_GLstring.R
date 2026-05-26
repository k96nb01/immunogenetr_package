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

  data_duplicates <- tribble(
    ~value,                  ~entry, ~possible_gene_location, ~locus, ~genotype_ambiguity, ~genotype, ~haplotype, ~allele,
    "HLA-A*02:01",           1,      1,                       1,      1,                   1,         1,          1,
    "HLA-A*02:01",           1,      1,                       1,      1,                   1,         1,          2,
  )

  result_FALSE <- ambiguity_table_to_GLstring(data_duplicates)
  result_TRUE <- ambiguity_table_to_GLstring(data_duplicates, remove_duplicates = TRUE)

  expect_equal(result_FALSE, "HLA-A*02:01/HLA-A*02:01")
  expect_equal(result_TRUE, "HLA-A*02:01")
})

# Regression test for the iteration-7 NA-propagation bug. The first draft of
# the v2 rewrite used paste(..., collapse = sep), which turns NA into the
# string "NA" and concatenates. v1's str_flatten returned NA if any element
# in the group was NA. HLA_prefix_add(NA) exercises this path end-to-end.
test_that("ambiguity_table_to_GLstring preserves NA in value", {
  # Ambiguity table of a single NA entry — this is the shape
  # GLstring_expand_longer(NA) produces.
  na_table <- tibble(
    value = NA_character_,
    entry = 1L, possible_gene_location = 1L, locus = 1L,
    genotype_ambiguity = 1L, genotype = 1L, haplotype = 1L, allele = 1L
  )
  expect_true(is.na(ambiguity_table_to_GLstring(na_table)))

  # Mixed group: at least one NA value inside a group should still
  # propagate NA for that group (str_flatten semantics). Here we build an
  # allele group with one real allele and one NA sibling.
  mixed_table <- tibble(
    value  = c("HLA-A*01:01", NA_character_),
    entry = c(1L, 1L),
    possible_gene_location = c(1L, 1L),
    locus = c(1L, 1L),
    genotype_ambiguity = c(1L, 1L),
    genotype = c(1L, 1L),
    haplotype = c(1L, 1L),
    allele = c(1L, 2L)
  )
  expect_true(is.na(ambiguity_table_to_GLstring(mixed_table)))
})
