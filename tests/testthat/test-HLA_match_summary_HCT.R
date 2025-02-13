library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_match_summary_HCT correctly calculates match summary for HCT", {
  GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
  GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

  result_Xof8_HvG <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof8")
  result_Xof8_GvH <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof8")
  result_Xof8_bidirectional <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof8")

  expect_equal(result_Xof8_HvG, 4)
  expect_equal(result_Xof8_GvH, 5)
  expect_equal(result_Xof8_bidirectional, 4)

  result_Xof10_HvG <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "HvG", match_grade = "Xof10")
  result_Xof10_GvH <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "GvH", match_grade = "Xof10")
  result_Xof10_bidirectional <- HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "bidirectional", match_grade = "Xof10")

  expect_type(result_Xof10_HvG, "integer")
  expect_type(result_Xof10_GvH, "integer")
  expect_type(result_Xof10_bidirectional, "integer")

  expect_equal(result_Xof10_HvG, 6)
  expect_equal(result_Xof10_GvH, 7)
  expect_equal(result_Xof10_bidirectional, 6)

  perfect_match <- HLA_match_summary_HCT(GL_string_recip, GL_string_recip, direction = "bidirectional", match_grade = "Xof10")
  expect_equal(perfect_match, 10)

  GL_string_mismatch <- "HLA-A*24:01^HLA-C*05:01+HLA-C*08:01^HLA-B*51:01+HLA-B*52:01^HLA-DRB1*15:01+HLA-DRB1*16:01^HLA-DQB1*05:01+HLA-DQB1*06:01"
  mismatch_result <- HLA_match_summary_HCT(GL_string_recip, GL_string_mismatch, direction = "bidirectional", match_grade = "Xof10")
  expect_equal(mismatch_result, 0)

  expect_error(HLA_match_summary_HCT(GL_string_recip, GL_string_donor, direction = "invalid"))
})
