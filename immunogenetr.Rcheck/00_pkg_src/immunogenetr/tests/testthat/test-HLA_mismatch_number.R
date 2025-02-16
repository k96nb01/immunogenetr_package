library(testthat)
library(dplyr)
library(stringr)

test_that("HLA_mismatch_number correctly calculates mismatch counts", {
  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*13:01+HLA-DRB1*14:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  result_GvH <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  result_bidirectional <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "bidirectional")
  result_SOT <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "SOT")

  expect_match(result_HvG, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_GvH, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_bidirectional, "HLA-A=1, HLA-B=1, HLA-DRB1=1")
  expect_match(result_SOT, "HLA-A=1, HLA-B=1, HLA-DRB1=1")

  result_single_locus <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus, 1)

  result_homozygous_1 <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 1)
  expect_equal(result_homozygous_1, 1)

  GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*44:02+HLA-B*44:02^HLA-DRB1*13:01+HLA-DRB1*14:01"
  result_homozygous_2 <- HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-B", direction = "HvG", homozygous_count = 2)
  expect_equal(result_homozygous_2, 2)

  GL_string_recip_match <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  GL_string_donor_match <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*13:01+HLA-DRB1*15:01"
  result_no_mismatch <- HLA_mismatch_number(GL_string_recip_match, GL_string_donor_match, loci, direction = "bidirectional")
  expect_match(result_no_mismatch, "HLA-A=0, HLA-B=0, HLA-DRB1=0")

  # Set the alleles
  A <- "HLA-A*01:01"
  B <- "HLA-A*02:05"
  C <- "HLA-A*24:02"
  D <- "HLA-A*31:03"
  N <- "HLA-A*68:11N"

  # Test the 2010 mismatch table.
  (mismatch_table_2010_test <- mismatch_table_2010
    %>% rename(Patient = patient, Donor = donor)
    # Assign the example alleles.
    %>% mutate(recipient_1 = case_when(
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
    ))
    # Turn the two alleles into a GL string.
    %>% mutate(GL_string_recip = str_c(recipient_1, recipient_2, sep = "+"),
               GL_string_donor = str_c(donor_1, donor_2, sep = "+"))
    %>% select(Patient, Donor, GL_string_recip, GL_string_donor, "#GvH", "#HvG", "#Max")
    # Calculate MM numbers for each row - use homozygous_count = 1 for the 2010 table.
    %>% mutate(
      GvH_hc1 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "GvH", 1),
      HvG_hc1 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "HvG", 1),
      bidirectional_hc1 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "bidirectional", 1)
    )
    %>%
      rename(GvH = "#GvH", HvG = "#HvG", Max = "#Max") %>%
      # Check that the calculated results match the consensus results.
      mutate(
        GvH_hc1_result = (GvH == GvH_hc1),
        HvG_hc1_result = (HvG == HvG_hc1),
        bidirectional_hc1_result = (Max == bidirectional_hc1)
      ) %>%
      # Check that for each row all values are correct.
      mutate(total_result = if_all(GvH_hc1_result:bidirectional_hc1_result)) %>%
      # Summarize to a single value if all were true.
      distinct(total_result) %>%
      pull(total_result)
  )

  expect_equal(mismatch_table_2010_test, TRUE)

  # Test the 2016 mismatch table
  (mismatch_table_2016_test <- mismatch_table_2016
    # Assign the example alleles.
    %>% mutate(recipient_1 = case_when(
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
    ))
    # Turn the two alleles into a GL string.
    %>% mutate(GL_string_recip = str_c(recipient_1, recipient_2, sep = "+"),
               GL_string_donor = str_c(donor_1, donor_2, sep = "+"))
    %>% select(Patient, Donor, GL_string_recip, GL_string_donor, "#GvH", "#HvG", "#Max")
    # Calculate MM numbers for each row - use homozygous_count = 2 for the 2016 table.
    %>% mutate(
      GvH_hc2 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "GvH", 2),
      HvG_hc2 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "HvG", 2),
      bidirectional_hc2 = HLA_mismatch_number(GL_string_recip, GL_string_donor, "HLA-A", "bidirectional", 2)
    )
    %>%
      rename(GvH = "#GvH", HvG = "#HvG", Max = "#Max") %>%
      # Check that the calculated results match the consensus results.
      mutate(
        GvH_hc2_result = (GvH == GvH_hc2),
        HvG_hc2_result = (HvG == HvG_hc2),
        bidirectional_hc2_result = (Max == bidirectional_hc2)
      ) %>%
      # Check that for each row all values are correct.
      mutate(total_result = if_all(GvH_hc2_result:bidirectional_hc2_result)) %>%
      # Summarize to a single value if all were true.
      distinct(total_result) %>%
      pull(total_result)
  )

  expect_equal(mismatch_table_2016_test, TRUE)
})
