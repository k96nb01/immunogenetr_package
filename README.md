
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immunogenetr <img src='man/figures/immunogenetr_sticker.png' align="right" height="139" />

<!-- badges: start -->

[![codecov](https://codecov.io/gh/k96nb01/immunogenetr_package/graph/badge.svg?token=16D4U43VET)](https://codecov.io/gh/k96nb01/immunogenetr_package)
[![R-CMD-check](https://github.com/k96nb01/immunogenetr_package/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/k96nb01/immunogenetr_package/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

immunogenetr is a comprehensive toolkit for clinical HLA informatics. It
is built on tidyverse principles and makes use of genotype list string
(GL string, <https://glstring.org/>) for storing and using HLA genotype
data.

Specific functionalities of this library include:

- **Coercion of HLA data** in tabular format to and from GL string.
- **Calculation of matching and mismatching** in all directions, with
  multiple output formats.
- **Automatic formatting of HLA data** for searching within a GL string.
- **Truncation of molecular HLA data** to a specific number of fields.
- **Reading HLA genotypes in HML files** and extracting the GL string.

## Table of Contents

- [Installation](#installation)
- [Usage](##usage)
- [License](#license)

## Installation

You may install immunogenetr from GitHub with the below lines of code.
Devtools is necessary for installation. If devtools is not installed,
you may run `install.packages("devtools")` first.

``` r
devtools::install_github("k96nb01/immunogenetr_package")
```

## Usage

To demonstrate some functionality of `immunogenetr` we will use an
internal dataset to perform match grades for a putative recipient/donor
pair.

``` r
library(immunogenetr)
library(tidyverse)

# The "HLA_typing_1" dataset is installed with immunogenetr, and contains high resolution typing at all classical 
# HLA loci for ten individuals.

print(HLA_typing_1)
```

| patient | A1 | A2 | C1 | C2 | B1 | B2 | DRB345_1 | DRB345_2 | DRB1_1 | DRB1_2 | DQA1_1 | DQA1_2 | DQB1_1 | DQB1_2 | DPA1_1 | DPA1_2 | DPB1_1 | DPB1_2 |
|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 1 | A\*24:02 | A\*29:02 | C\*07:04 | C\*16:01 | B\*44:02 | B\*44:03 | DRB5\*01:01 | DRB5\*01:01 | DRB1\*15:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*01:02 | DQB1\*06:02 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*03:01 | DPB1\*04:01 |
| 2 | A\*02:01 | A\*11:05 | C\*07:01 | C\*07:02 | B\*07:02 | B\*08:01 | DRB3\*01:01 | DRB4\*01:03 | DRB1\*03:01 | DRB1\*04:01 | DQA1\*03:03 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*03:01 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |
| 3 | A\*02:01 | A\*26:18 | C\*02:02 | C\*03:04 | B\*27:05 | B\*54:01 | DRB3\*02:02 | DRB4\*01:03 | DRB1\*04:04 | DRB1\*14:54 | DQA1\*01:04 | DQA1\*03:01 | DQB1\*03:02 | DQB1\*05:02 | DPA1\*01:03 | DPA1\*02:02 | DPB1\*02:01 | DPB1\*05:01 |
| 4 | A\*29:02 | A\*30:02 | C\*06:02 | C\*07:01 | B\*08:01 | B\*13:02 | DRB4\*01:03 | DRB4\*01:03 | DRB1\*04:01 | DRB1\*07:01 | DQA1\*02:01 | DQA1\*03:01 | DQB1\*02:02 | DQB1\*03:02 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*01:01 | DPB1\*16:01 |
| 5 | A\*02:05 | A\*24:02 | C\*07:18 | C\*12:03 | B\*35:03 | B\*58:01 | DRB3\*02:02 | DRB3\*02:02 | DRB1\*03:01 | DRB1\*14:54 | DQA1\*01:04 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*05:03 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*10:01 | DPB1\*124:01 |
| 6 | A\*01:01 | A\*24:02 | C\*07:01 | C\*14:02 | B\*49:01 | B\*51:01 | DRB3\*03:01 | DRBX\*NNNN | DRB1\*08:01 | DRB1\*13:02 | DQA1\*01:02 | DQA1\*04:01 | DQB1\*04:02 | DQB1\*06:04 | DPA1\*01:03 | DPA1\*01:04 | DPB1\*04:01 | DPB1\*15:01 |
| 7 | A\*03:01 | A\*03:01 | C\*03:03 | C\*16:01 | B\*15:01 | B\*51:01 | DRB4\*01:01 | DRBX\*NNNN | DRB1\*01:01 | DRB1\*07:01 | DQA1\*01:01 | DQA1\*02:01 | DQB1\*02:02 | DQB1\*05:01 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |
| 8 | A\*01:01 | A\*32:01 | C\*06:02 | C\*07:02 | B\*08:01 | B\*37:01 | DRB3\*02:02 | DRB5\*01:01 | DRB1\*03:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*04:01 | DPB1\*14:01 |
| 9 | A\*03:01 | A\*30:01 | C\*07:02 | C\*12:03 | B\*07:02 | B\*38:01 | DRB3\*01:01 | DRB5\*01:01 | DRB1\*03:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |
| 10 | A\*02:05 | A\*11:01 | C\*07:18 | C\*16:02 | B\*51:01 | B\*58:01 | DRB3\*03:01 | DRB5\*01:01 | DRB1\*13:02 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*01:03 | DQB1\*06:01 | DQB1\*06:09 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*02:01 | DPB1\*104:01 |

``` r
# immunogenetr uses genotype list strings (GL strings) for most functions, including the matching and mismatching 
# functions. To easily convert the genotypes found in "HLA_typing_1" to GL strings we can use the 
# `HLA_columns_to_GLstring` function:

HLA_typing_1_GLstring <- HLA_typing_1 %>% 
  mutate(GL_string = HLA_columns_to_GLstring(., HLA_typing_columns = A1:DPB1_2
), .after = patient) %>% # Note the syntax for the `HLA_columns_to_GLstring` arguments - 
# when this function is used inside of a `mutate` function 
# to make a new column in a data frame, "." is used in the 
# first argument to tell the function to use the working 
# data frame as the source of the HLA typing columns.
  select(patient, GL_string)

print(HLA_typing_1_GLstring)
```

| patient | GL_string |
|---:|:---|
| 1 | HLA-A\*24:02+HLA-A\*29:02^HLA-C\*07:04+HLA-C\*16:01^HLA-B\*44:02+HLA-B\*44:03^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*15:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:02^HLA-DQB1\*06:02+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*03:01+HLA-DPB1\*04:01 |
| 2 | HLA-A\*02:01+HLA-A\*11:05^HLA-C\*07:01+HLA-C\*07:02^HLA-B\*07:02+HLA-B\*08:01^HLA-DRB3\*01:01+HLA-DRB3\*01:03^HLA-DRB1\*03:01+HLA-DRB1\*04:01^HLA-DQA1\*03:03+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*03:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| 3 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 4 | HLA-A\*29:02+HLA-A\*30:02^HLA-C\*06:02+HLA-C\*07:01^HLA-B\*08:01+HLA-B\*13:02^HLA-DRB3\*01:03+HLA-DRB3\*01:03^HLA-DRB1\*04:01+HLA-DRB1\*07:01^HLA-DQA1\*02:01+HLA-DQA1\*03:01^HLA-DQB1\*02:02+HLA-DQB1\*03:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*01:01+HLA-DPB1\*16:01 |
| 5 | HLA-A\*02:05+HLA-A\*24:02^HLA-C\*07:18+HLA-C\*12:03^HLA-B\*35:03+HLA-B\*58:01^HLA-DRB3\*02:02+HLA-DRB3\*02:02^HLA-DRB1\*03:01+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*05:03^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*10:01+HLA-DPB1\*124:01 |
| 6 | HLA-A\*01:01+HLA-A\*24:02^HLA-C\*07:01+HLA-C\*14:02^HLA-B\*49:01+HLA-B\*51:01^HLA-DRB3\*03:01^HLA-DRB1\*08:01+HLA-DRB1\*13:02^HLA-DQA1\*01:02+HLA-DQA1\*04:01^HLA-DQB1\*04:02+HLA-DQB1\*06:04^HLA-DPA1\*01:03+HLA-DPA1\*01:04^HLA-DPB1\*04:01+HLA-DPB1\*15:01 |
| 7 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| 8 | HLA-A\*01:01+HLA-A\*32:01^HLA-C\*06:02+HLA-C\*07:02^HLA-B\*08:01+HLA-B\*37:01^HLA-DRB3\*02:02+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*04:01+HLA-DPB1\*14:01 |
| 9 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| 10 | HLA-A\*02:05+HLA-A\*11:01^HLA-C\*07:18+HLA-C\*16:02^HLA-B\*51:01+HLA-B\*58:01^HLA-DRB3\*03:01+HLA-DRB3\*01:01^HLA-DRB1\*13:02+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:03^HLA-DQB1\*06:01+HLA-DQB1\*06:09^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*02:01+HLA-DPB1\*104:01 |

The “HLA_typing_1_GLstring” data frame now contains a row with a GL
string for each individual, containing their full HLA genotype in a
single string. Let’s select one individual to act as a recipient, and
one to act as a donor.

``` r
# Select one case each for recipient and donor.
HLA_typing_1_GLstring_recipient <- HLA_typing_1_GLstring %>% 
  filter(patient == 7) %>% 
  rename(GL_string_recipient = GL_string, case = patient)

HLA_typing_1_GLstring_donor <- HLA_typing_1_GLstring %>% 
  filter(patient == 9) %>% 
  rename(GL_string_donor = GL_string) %>% 
  select(-patient)

# Combine the tables so recipient and donor are on the same row.
HLA_typing_1_recip_donor <- bind_cols(
  HLA_typing_1_GLstring_recipient, 
  HLA_typing_1_GLstring_donor
  )

print(HLA_typing_1_recip_donor)
```

| case | GL_string_recipient | GL_string_donor |
|---:|:---|:---|
| 7 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |

We now have a data frame with a recipient and donor HLA genotype on one
row. Let’s try out some of the mismatching functions on this data.

``` r
HLA_typing_1_recip_donor_mismatches <- HLA_typing_1_recip_donor %>% 
  mutate(A_MM_GvH = HLA_mismatch_logical(
                      GL_string_recipient, 
                      GL_string_donor, 
                      "HLA-A", 
                      direction = "GvH"), 
                    .after = case) %>% 
  mutate(A_MM_HvG = HLA_mismatch_logical(
                      GL_string_recipient, 
                      GL_string_donor, 
                      "HLA-A", 
                      direction = "HvG"), 
                    .after = A_MM_GvH)

print(HLA_typing_1_recip_donor_mismatches)
```

| case | A_MM_GvH | A_MM_HvG | GL_string_recipient | GL_string_donor |
|---:|:---|:---|:---|:---|
| 7 | TRUE | TRUE | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |

The `HLA_mismatch_logical` function determines if there are any
mismatches at a particular locus. We’ve determined that at the HLA-A
locus there are not any mismatches in the graft-versus-host direction,
but are in the host-versus-graft direction. We can use the
`HLA_mismatched_alleles` function to tell us what those mismatches are:

``` r
HLA_typing_1_recip_donor_mismatched_allles <- HLA_typing_1_recip_donor %>% 
  mutate(A_HvG_MMs = HLA_mismatched_alleles(
                        GL_string_recipient, 
                        GL_string_donor, 
                        "HLA-A", 
                        direction = "HvG"), 
                      .after = case)

print(HLA_typing_1_recip_donor_mismatched_allles)
```

| case | A_HvG_MMs | GL_string_recipient | GL_string_donor |
|---:|:---|:---|:---|
| 7 | HLA-A\*30:01 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |

The `HLA_mismatched_alleles` function reported that the “HLA-A\*30:01”
allele was mismatched in the HvG direction. Sometimes, however, we
simply want to know how many mismatches are at a particular locus. We
can do that with the `HLA_mismatch_number` function:

``` r
# Determine the number of bidirectional mismatches at several loci.
HLA_typing_1_recip_donor_MM_number <- HLA_typing_1_recip_donor %>% 
  mutate(ABCDRB1_MM = HLA_mismatch_number(
                        GL_string_recipient, 
                        GL_string_donor, 
                        c("HLA-A", "HLA-B", "HLA-C", "HLA-DRB1"), 
                        direction = "bidirectional"), 
                      .after = case)

print(HLA_typing_1_recip_donor_MM_number)
```

| case | ABCDRB1_MM | GL_string_recipient | GL_string_donor |
|---:|:---|:---|:---|
| 7 | HLA-A=1 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |

We might want to calculate an HLA match summary for stem cell
transplantation. We can use the `HLA_match_summarry_HCT` function for
this:

``` r
# The match_grade argument of "Xof8" will return the number of matches at the HLA-A, B, C, and DRB1 loci.
HLA_typing_1_recip_donor_8of8_matching <- HLA_typing_1_recip_donor %>% 
  mutate(ABCDRB1_matching = HLA_match_summary_HCT(
                              GL_string_recipient, 
                              GL_string_donor, 
                              direction = "bidirectional", 
                              match_grade = "Xof8"), 
                            .after = case)

print(HLA_typing_1_recip_donor_8of8_matching)
```

| case | ABCDRB1_matching | GL_string_recipient | GL_string_donor |
|---:|---:|:---|:---|
| 7 | 1 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |

Clearly, this recipient and donor are not a great match. Let’s see how
we could use this workflow to find the best-matched donor from several
options. To do this, we’ll choose a case from “HLA_typing_1” and compare
it to all the cases in that data set:

``` r
# Select one case to be the recipient.
HLA_typing_1_GLstring_candidate <- HLA_typing_1_GLstring %>% 
  filter(patient == 3) %>% 
  select(GL_string) %>% 
  rename(GL_string_recip = GL_string)

# Join the recipient to the 10-donor list and perform matching
HLA_typing_1_GLstring_donors <- HLA_typing_1_GLstring %>% 
  rename(GL_string_donor = GL_string, donor = patient) %>% 
  cross_join(HLA_typing_1_GLstring_candidate) %>% 
  mutate(ABCDRB1_matching = HLA_match_summary_HCT(
                              GL_string_recip, 
                              GL_string_donor, 
                              direction = "bidirectional", 
                              match_grade = "Xof8"), 
                            .after = donor) %>% 
  arrange(desc(ABCDRB1_matching))

print(HLA_typing_1_GLstring_donors)
```

| donor | ABCDRB1_matching | GL_string_donor | GL_string_recip |
|---:|---:|:---|:---|
| 3 | 8 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 2 | 1 | HLA-A\*02:01+HLA-A\*11:05^HLA-C\*07:01+HLA-C\*07:02^HLA-B\*07:02+HLA-B\*08:01^HLA-DRB3\*01:01+HLA-DRB3\*01:03^HLA-DRB1\*03:01+HLA-DRB1\*04:01^HLA-DQA1\*03:03+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*03:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 5 | 1 | HLA-A\*02:05+HLA-A\*24:02^HLA-C\*07:18+HLA-C\*12:03^HLA-B\*35:03+HLA-B\*58:01^HLA-DRB3\*02:02+HLA-DRB3\*02:02^HLA-DRB1\*03:01+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*05:03^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*10:01+HLA-DPB1\*124:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 1 | 0 | HLA-A\*24:02+HLA-A\*29:02^HLA-C\*07:04+HLA-C\*16:01^HLA-B\*44:02+HLA-B\*44:03^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*15:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:02^HLA-DQB1\*06:02+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*03:01+HLA-DPB1\*04:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 4 | 0 | HLA-A\*29:02+HLA-A\*30:02^HLA-C\*06:02+HLA-C\*07:01^HLA-B\*08:01+HLA-B\*13:02^HLA-DRB3\*01:03+HLA-DRB3\*01:03^HLA-DRB1\*04:01+HLA-DRB1\*07:01^HLA-DQA1\*02:01+HLA-DQA1\*03:01^HLA-DQB1\*02:02+HLA-DQB1\*03:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*01:01+HLA-DPB1\*16:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 6 | 0 | HLA-A\*01:01+HLA-A\*24:02^HLA-C\*07:01+HLA-C\*14:02^HLA-B\*49:01+HLA-B\*51:01^HLA-DRB3\*03:01^HLA-DRB1\*08:01+HLA-DRB1\*13:02^HLA-DQA1\*01:02+HLA-DQA1\*04:01^HLA-DQB1\*04:02+HLA-DQB1\*06:04^HLA-DPA1\*01:03+HLA-DPA1\*01:04^HLA-DPB1\*04:01+HLA-DPB1\*15:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 7 | 0 | HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 8 | 0 | HLA-A\*01:01+HLA-A\*32:01^HLA-C\*06:02+HLA-C\*07:02^HLA-B\*08:01+HLA-B\*37:01^HLA-DRB3\*02:02+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*04:01+HLA-DPB1\*14:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 9 | 0 | HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| 10 | 0 | HLA-A\*02:05+HLA-A\*11:01^HLA-C\*07:18+HLA-C\*16:02^HLA-B\*51:01+HLA-B\*58:01^HLA-DRB3\*03:01+HLA-DRB3\*01:01^HLA-DRB1\*13:02+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:03^HLA-DQB1\*06:01+HLA-DQB1\*06:09^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*02:01+HLA-DPB1\*104:01 | HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |

We can see that donor 3 is the only donor with an 8/8 match for the
recipient.

## License

This project is licensed under the GNU General Public License v3.0. See
the [LICENSE](LICENSE) file for details.

</div>
</div>
