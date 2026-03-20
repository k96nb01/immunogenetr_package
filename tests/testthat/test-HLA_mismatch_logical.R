library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_mismatch_logical correctly identifies presence of mismatches", {
  GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
  GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-DRB3*03:01"

  result_HvG <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "HvG")
  expect_true(result_HvG)

  result_GvH <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "GvH")
  expect_true(result_GvH)

  result_DRB3 <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-DRB3/4/5", direction = "HvG")
  expect_false(result_DRB3)

  result_bidirectional <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "bidirectional")
  expect_true(result_bidirectional)

  result_multi_loci <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_match(result_multi_loci, "HLA-A=TRUE")
  expect_match(result_multi_loci, "HLA-DRB3/4/5=FALSE")

  result_SOT <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci = "HLA-A", direction = "SOT")
  expect_true(result_SOT)

  GL_string_donor_same <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
  result_no_mismatch <- HLA_mismatch_logical(GL_string_recip, GL_string_donor_same, loci = c("HLA-A", "HLA-DRB3/4/5"), direction = "bidirectional")
  expect_match(result_no_mismatch, "HLA-A=FALSE")
  expect_match(result_no_mismatch, "HLA-DRB3/4/5=FALSE")
})


# --- Input validation tests ---

test_that("HLA_mismatch_logical rejects NULL inputs", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(NULL, gl, "HLA-A", "HvG"), "GL_string_recip")
  expect_error(HLA_mismatch_logical(gl, NULL, "HLA-A", "HvG"), "GL_string_donor")
  expect_error(HLA_mismatch_logical(gl, gl, NULL, "HvG"), "loci")
})

test_that("HLA_mismatch_logical rejects non-character GL strings", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(123, gl, "HLA-A", "HvG"), "must be a character")
})

test_that("HLA_mismatch_logical rejects invalid direction", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_logical(gl, gl, "HLA-A", "invalid"))
})

test_that("HLA_mismatch_logical returns FALSE for perfect match", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  # Single locus
  expect_false(HLA_mismatch_logical(gl, gl, "HLA-A", "bidirectional"))
  # Multiple loci
  result <- HLA_mismatch_logical(gl, gl, c("HLA-A", "HLA-B"), "bidirectional")
  expect_match(result, "HLA-A=FALSE")
  expect_match(result, "HLA-B=FALSE")
})

test_that("HLA_mismatch_logical agrees with mismatch_table_2016 consensus (homozygous_count = 2)", {
  # Note: HLA_mismatch_logical does not expose a homozygous_count parameter —
  # it always uses the default of 2 via HLA_mismatch_base. Therefore,
  # only the 2016 table (which expects homozygous_count = 2) is tested here.
  # The 2010 table (homozygous_count = 1) is tested in test-HLA_mismatch_number.R.
  # Define symbolic alleles to substitute into the table.
  A <- "HLA-A*01:01"
  B <- "HLA-A*02:05"
  C <- "HLA-A*24:02"
  D <- "HLA-A*31:03"
  N <- "HLA-A*68:11N"

  # Build GL strings from the 2016 table's symbolic allele pairs.
  mismatch_table_2016_logical <- mismatch_table_2016 %>%
    # Assign the example alleles based on symbolic codes.
    mutate(recipient_1 = case_when(
      str_detect(Patient, "^A") ~ A,
      str_detect(Patient, "^N") ~ N
    ), recipient_2 = case_when(
      str_detect(Patient, "A$") ~ A,
      str_detect(Patient, "B$") ~ B,
      str_detect(Patient, "N$") ~ N
    ), donor_1 = case_when(
      str_detect(Donor, "^A") ~ A,
      str_detect(Donor, "^B") ~ B,
      str_detect(Donor, "^C") ~ C,
      str_detect(Donor, "^N") ~ N
    ), donor_2 = case_when(
      str_detect(Donor, "A$") ~ A,
      str_detect(Donor, "B$") ~ B,
      str_detect(Donor, "C$") ~ C,
      str_detect(Donor, "D$") ~ D,
      str_detect(Donor, "N$") ~ N
    )) %>%
    # Turn the two alleles into a GL string.
    mutate(
      GL_string_recip = str_c(recipient_1, recipient_2, sep = "+"),
      GL_string_donor = str_c(donor_1, donor_2, sep = "+")
    ) %>%
    select(Patient, Donor, GL_string_recip, GL_string_donor, "#GvH", "#HvG", "#Max") %>%
    rename(GvH = "#GvH", HvG = "#HvG", Max = "#Max") %>%
    # Calculate logical mismatch for each direction.
    mutate(
      GvH_logical = HLA_mismatch_logical(GL_string_recip, GL_string_donor, "HLA-A", "GvH"),
      HvG_logical = HLA_mismatch_logical(GL_string_recip, GL_string_donor, "HLA-A", "HvG"),
      bidir_logical = HLA_mismatch_logical(GL_string_recip, GL_string_donor, "HLA-A", "bidirectional")
    ) %>%
    # Derive expected logical values from the consensus mismatch counts.
    mutate(
      GvH_expected = (GvH > 0),
      HvG_expected = (HvG > 0),
      bidir_expected = (Max > 0)
    ) %>%
    # Check that calculated results match expected results.
    mutate(
      GvH_result = (GvH_logical == GvH_expected),
      HvG_result = (HvG_logical == HvG_expected),
      bidir_result = (bidir_logical == bidir_expected)
    ) %>%
    # Check that for each row all values are correct.
    mutate(total_result = if_all(GvH_result:bidir_result)) %>%
    # Summarize to a single value if all were true.
    distinct(total_result) %>%
    pull(total_result)

  expect_equal(mismatch_table_2016_logical, TRUE)
})

test_that("HLA_mismatch_logical handles GvH direction with multiple loci", {
  # This specifically tests the multi-loci GvH branch (lines 102-104),
  # which was not covered by existing tests that only used GvH with a single locus.
  GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-B*07:02+HLA-B*08:01"
  GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-B*07:02+HLA-B*08:01"

  result <- HLA_mismatch_logical(GL_string_recip, GL_string_donor,
                                  loci = c("HLA-A", "HLA-B"), direction = "GvH")

  # HLA-A should be mismatched (donor has different alleles).
  expect_match(result, "HLA-A=TRUE")
  # HLA-B should match (same alleles).
  expect_match(result, "HLA-B=FALSE")
})

test_that("HLA_mismatch_logical works with vectorized inputs", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*03:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  # Single locus: should return logical vector of length 2
  result <- HLA_mismatch_logical(recip, donor, "HLA-A", "HvG")
  expect_length(result, 2)
  expect_true(result[1])
  expect_false(result[2])
})
