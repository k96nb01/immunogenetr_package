library(testthat)
library(stringr)
library(dplyr)

test_that("HLA_mismatch_base correctly identifies mismatches", {
  GL_string_recip <- "HLA-A*02:01+HLA-A*03:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*04:01+HLA-DRB1*13:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  expect_equal(result_HvG, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  result_GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  expect_equal(result_GvH, "HLA-A=HLA-A*02:01, HLA-B=HLA-B*08:01, HLA-DRB1=HLA-DRB1*07:01")

  result_single_locus <- HLA_mismatch_base(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus, "HLA-A*01:01")

  result_HvG_homo1 <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG", homozygous_count = 1)
  expect_equal(result_HvG_homo1, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  expect_error(
    HLA_mismatch_base(c(GL_string_recip, GL_string_recip), GL_string_donor, loci, direction = "HvG"),
    "Recipient and donor GL strings must be of equal length"
  )
})


test_that("DRB3/4/5 and DR51/52/53 absent on both sides", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"

  loci_mol <- c("HLA-A", "HLA-DRB3/4/5")
  out_mol <- HLA_mismatch_base(recip, donor, loci_mol, direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")

  loci_ser <- c("HLA-A", "HLA-DR51/52/53")
  out_ser <- HLA_mismatch_base(recip, donor, loci_ser, direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")
})


test_that("DRB3/4/5 is in one but not in the other", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")
})


test_that("DRB51/52/53 is in one but not in the other", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")
})


test_that("DRB3/4/5 or DR51/52/53 as the only tested allele", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_mol <- HLA_mismatch_base(recip, donor, "HLA-DRB3/4/5", direction = "HvG")
  expect_true(is.na(out_mol))

  out_ser <- HLA_mismatch_base(recip, donor, "HLA-DR51/52/53", direction = "HvG")
  expect_true(is.na(out_ser))
})


test_that("Matching across DRB3/4/5 (molecular) and DR51/52/53 (serologic)", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=HLA-DR52+HLA-DR53")

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=HLA-DR52+HLA-DR53")
})

test_that("A genotype without any DRB3/4/5 alleles compared to a genotype with will have a mismatch", {
  recip <- "HLA-DRB1*01:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-DRB1*01:01^HLA-B*15:01"

  mismatches <- HLA_mismatch_base(recip, donor, loci = "HLA-DRB3/4/5", direction = "GvH")
  expect_equal(mismatches, "HLA-DRB3*01:01+HLA-DRB4*01:01")

  no_mismatches <- HLA_mismatch_base(recip, donor, loci = "HLA-DRB3/4/5", direction = "HvG")
  expect_equal(no_mismatches, NA_character_)

  expect_error(
    HLA_mismatch_base(recip, donor, loci = "HLA-B", direction = "HvG"),
    "Either the recipient and/or donor GL strings are missing these loci: HLA-B"
  )

  recip <- "HLA-DR1^HLA-DR52^HLA-DRB53"
  donor <- "HLA-DR1^HLA-B*75"

  sero_MM <- HLA_mismatch_base(recip, donor, loci = "HLA-DR51/52/53", direction = "GvH")
  expect_equal(sero_MM, "HLA-DR52+HLA-DRB53")

  sero_NA <- HLA_mismatch_base(recip, donor, loci = "HLA-DR51/52/53", direction = "HvG") # NA
  expect_equal(sero_NA, NA_character_)
})

