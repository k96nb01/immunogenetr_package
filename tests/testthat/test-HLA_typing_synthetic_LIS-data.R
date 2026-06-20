library(testthat)

# The HLA_typing_synthetic_LIS dataset is realistic, deliberately-messy LIS-style
# typing data (see R/HLA_typing_synthetic_LIS-data.R). These guards keep it usable
# as development/test data for HLA_columns_to_GLstring: the whole table must
# convert cleanly in both nomenclatures, with no malformed serologic-plus-
# asterisk loci (the issue #40 failure mode).

test_that("HLA_typing_synthetic_LIS has the expected shape and key columns", {
  expect_s3_class(HLA_typing_synthetic_LIS, "tbl_df")
  expect_equal(nrow(HLA_typing_synthetic_LIS), 63L)
  expect_true(all(c("Cw1Cd", "Cw2Cd", "mC1Cd", "mC2Cd", "mDPB12cd") %in%
                    names(HLA_typing_synthetic_LIS)))
})

test_that("HLA_columns_to_GLstring converts the whole synthetic table cleanly", {
  ser <- HLA_columns_to_GLstring(HLA_typing_synthetic_LIS, c(A1Cd:dq2cd),
                                 suffix_to_remove = "Cd")
  mol <- HLA_columns_to_GLstring(HLA_typing_synthetic_LIS, c(mA1Cd:mDPB12cd),
                                 prefix_to_remove = "m", suffix_to_remove = "Cd")

  expect_length(ser, 63L)
  expect_length(mol, 63L)

  # No malformed "<serologic-locus>*" tokens (e.g. "HLA-Cw*17", "HLA-Bw*4").
  expect_false(any(grepl("HLA-(Cw|Bw|DR|DQ|DPB|DPA|DQA)\\*", ser)))

  # The row with raw Cw values "*12"/"*17" renders as serologic Cw, not "Cw*".
  expect_true(grepl("HLA-Cw12+HLA-Cw17", ser[6], fixed = TRUE))
  expect_true(grepl("HLA-C*12:03+HLA-C*17:03", mol[6], fixed = TRUE))
})
