
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immunogenetr <img src='man/figures/immunogenetr_sticker.png' align="right" height="139" />

<!-- badges: start -->

[![codecov](https://codecov.io/gh/k96nb01/immunogenetr_package/graph/badge.svg?token=16D4U43VET)](https://codecov.io/gh/k96nb01/immunogenetr_package)
[![R-CMD-check](https://github.com/k96nb01/immunogenetr_package/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/k96nb01/immunogenetr_package/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

immunogenetr is a comprehensive toolkit that streamlines human leukocyte
antigen (HLA) informatics with a robust suite of functions for managing
and standardizing HLA data. It is built on tidyverse principles with the
aim of delivering clear, consistent, and modular code and simplifying
workflow integration.

Specific functionalities of this library include but are not limited to:

- **Identification of mismatches** for host vs. graft, graft vs. host,
  and bidirectional analyses for data in both serological and molecular
  formats
- **Translation** of tables, such as HLA columns or ambiguity tables,
  into proper GL strings
- **Coercion of wild-caught HLA data** to and from GL string
- **Expression of match summaries** for hematopoietic cell
  transplantation (HCT) analyses

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

An example workflow could be as follows:

```
# Step 1: Read in a table from project files
file <- HLA_typing_1[, -1]
```

The expected file output is

| A1 | A2 | C1 | C2 | B1 | B2 | DRB345_1 | DRB345_2 | DRB1_1 | DRB1_2 | DQA1_1 | DQA1_2 | DQB1_1 | DQB1_2 | DPA1_1 | DPA1_2 | DPB1_1 | DPB1_2 |  |
|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| A\*24:02 | A\*29:02 | C\*07:04 | C\*16:01 | B\*44:02 | B\*44:03 | DRB5\*01:01 | DRB5\*01:01 | DRB1\*15:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*01:02 | DQB1\*06:02 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*03:01 | DPB1\*04:01 |  |
| A\*02:01 | A\*11:05 | C\*07:01 | C\*07:02 | B\*07:02 | B\*08:01 | DRB3\*01:01 | DRB4\*01:03 | DRB1\*03:01 | DRB1\*04:01 | DQA1\*03:03 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*03:01 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |  |
| A\*02:01 | A\*26:18 | C\*02:02 | C\*03:04 | B\*27:05 | B\*54:01 | DRB3\*02:02 | DRB4\*01:03 | DRB1\*04:04 | DRB1\*14:54 | DQA1\*01:04 | DQA1\*03:01 | DQB1\*03:02 | DQB1\*05:02 | DPA1\*01:03 | DPA1\*02:02 | DPB1\*02:01 | DPB1\*05:01 |  |
| A\*29:02 | A\*30:02 | C\*06:02 | C\*07:01 | B\*08:01 | B\*13:02 | DRB4\*01:03 | DRB4\*01:03 | DRB1\*04:01 | DRB1\*07:01 | DQA1\*02:01 | DQA1\*03:01 | DQB1\*02:02 | DQB1\*03:02 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*01:01 | DPB1\*16:01 |  |
| A\*02:05 | A\*24:02 | C\*07:18 | C\*12:03 | B\*35:03 | B\*58:01 | DRB3\*02:02 | DRB3\*02:02 | DRB1\*03:01 | DRB1\*14:54 | DQA1\*01:04 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*05:03 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*10:01 | DPB1\*124:01 |  |
| A\*01:01 | A\*24:02 | C\*07:01 | C\*14:02 | B\*49:01 | B\*51:01 | DRB3\*03:01 | DRBX\*NNNN | DRB1\*08:01 | DRB1\*13:02 | DQA1\*01:02 | DQA1\*04:01 | DQB1\*04:02 | DQB1\*06:04 | DPA1\*01:03 | DPA1\*01:04 | DPB1\*04:01 | DPB1\*15:01 |  |
| A\*03:01 | A\*03:01 | C\*03:03 | C\*16:01 | B\*15:01 | B\*51:01 | DRB4\*01:01 | DRBX\*NNNN | DRB1\*01:01 | DRB1\*07:01 | DQA1\*01:01 | DQA1\*02:01 | DQB1\*02:02 | DQB1\*05:01 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |  |
| A\*01:01 | A\*32:01 | C\*06:02 | C\*07:02 | B\*08:01 | B\*37:01 | DRB3\*02:02 | DRB5\*01:01 | DRB1\*03:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*02:01 | DPB1\*04:01 | DPB1\*14:01 |  |
| A\*03:01 | A\*30:01 | C\*07:02 | C\*12:03 | B\*07:02 | B\*38:01 | DRB3\*01:01 | DRB5\*01:01 | DRB1\*03:01 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*05:01 | DQB1\*02:01 | DQB1\*06:02 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*04:01 | DPB1\*04:01 |  |
| A\*02:05 | A\*11:01 | C\*07:18 | C\*16:02 | B\*51:01 | B\*58:01 | DRB3\*03:01 | DRB5\*01:01 | DRB1\*13:02 | DRB1\*15:01 | DQA1\*01:02 | DQA1\*01:03 | DQB1\*06:01 | DQB1\*06:09 | DPA1\*01:03 | DPA1\*01:03 | DPB1\*02:01 | DPB1\*104:01 |  |

```
# Step 2: Convert all rows to GL strings
GL_strings <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything(), prefix_to_remove = "HLA-")
```

<div style="overflow-x: auto; white-space: nowrap;">

| GL strings |
|:---|
| HLA-A\*24:02+HLA-A\*29:02^HLA-C\*07:04+HLA-C\*16:01^HLA-B\*44:02+HLA-B\*44:03^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*15:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:02^HLA-DQB1\*06:02+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*03:01+HLA-DPB1\*04:01 |
| HLA-A\*02:01+HLA-A\*11:05^HLA-C\*07:01+HLA-C\*07:02^HLA-B\*07:02+HLA-B\*08:01^HLA-DRB3\*01:01+HLA-DRB3\*01:03^HLA-DRB1\*03:01+HLA-DRB1\*04:01^HLA-DQA1\*03:03+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*03:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| HLA-A\*02:01+HLA-A\*26:18^HLA-C\*02:02+HLA-C\*03:04^HLA-B\*27:05+HLA-B\*54:01^HLA-DRB3\*02:02+HLA-DRB3\*01:03^HLA-DRB1\*04:04+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*03:01^HLA-DQB1\*03:02+HLA-DQB1\*05:02^HLA-DPA1\*01:03+HLA-DPA1\*02:02^HLA-DPB1\*02:01+HLA-DPB1\*05:01 |
| HLA-A\*29:02+HLA-A\*30:02^HLA-C\*06:02+HLA-C\*07:01^HLA-B\*08:01+HLA-B\*13:02^HLA-DRB3\*01:03+HLA-DRB3\*01:03^HLA-DRB1\*04:01+HLA-DRB1\*07:01^HLA-DQA1\*02:01+HLA-DQA1\*03:01^HLA-DQB1\*02:02+HLA-DQB1\*03:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*01:01+HLA-DPB1\*16:01 |
| HLA-A\*02:05+HLA-A\*24:02^HLA-C\*07:18+HLA-C\*12:03^HLA-B\*35:03+HLA-B\*58:01^HLA-DRB3\*02:02+HLA-DRB3\*02:02^HLA-DRB1\*03:01+HLA-DRB1\*14:54^HLA-DQA1\*01:04+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*05:03^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*10:01+HLA-DPB1\*124:01 |
| HLA-A\*01:01+HLA-A\*24:02^HLA-C\*07:01+HLA-C\*14:02^HLA-B\*49:01+HLA-B\*51:01^HLA-DRB3\*03:01^HLA-DRB1\*08:01+HLA-DRB1\*13:02^HLA-DQA1\*01:02+HLA-DQA1\*04:01^HLA-DQB1\*04:02+HLA-DQB1\*06:04^HLA-DPA1\*01:03+HLA-DPA1\*01:04^HLA-DPB1\*04:01+HLA-DPB1\*15:01 |
| HLA-A\*03:01+HLA-A\*03:01^HLA-C\*03:03+HLA-C\*16:01^HLA-B\*15:01+HLA-B\*51:01^HLA-DRB3\*01:01^HLA-DRB1\*01:01+HLA-DRB1\*07:01^HLA-DQA1\*01:01+HLA-DQA1\*02:01^HLA-DQB1\*02:02+HLA-DQB1\*05:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| HLA-A\*01:01+HLA-A\*32:01^HLA-C\*06:02+HLA-C\*07:02^HLA-B\*08:01+HLA-B\*37:01^HLA-DRB3\*02:02+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*02:01^HLA-DPB1\*04:01+HLA-DPB1\*14:01 |
| HLA-A\*03:01+HLA-A\*30:01^HLA-C\*07:02+HLA-C\*12:03^HLA-B\*07:02+HLA-B\*38:01^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*03:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 |
| HLA-A\*02:05+HLA-A\*11:01^HLA-C\*07:18+HLA-C\*16:02^HLA-B\*51:01+HLA-B\*58:01^HLA-DRB3\*03:01+HLA-DRB3\*01:01^HLA-DRB1\*13:02+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:03^HLA-DQB1\*06:01+HLA-DQB1\*06:09^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*02:01+HLA-DPB1\*104:01 |

<div>

```
# Step 3: Find donor and recipient
donor <- GL_strings[1]
recip <- GL_strings[2]

# Step 4: Only consider first two fields
HLA_truncate(recip) 
HLA_truncate(donor) 

HCT_table <- data.frame(
    recip_data = recip,
    donor_data = donor
)
```

| recip_data | donor_data |
|:---|:---|
| HLA-A\*02:01+HLA-A\*11:05^HLA-C\*07:01+HLA-C\*07:02^HLA-B\*07:02+HLA-B\*08:01^HLA-DRB3\*01:01+HLA-DRB3\*01:03^HLA-DRB1\*03:01+HLA-DRB1\*04:01^HLA-DQA1\*03:03+HLA-DQA1\*05:01^HLA-DQB1\*02:01+HLA-DQB1\*03:01^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*04:01+HLA-DPB1\*04:01 | HLA-A\*24:02+HLA-A\*29:02^HLA-C\*07:04+HLA-C\*16:01^HLA-B\*44:02+HLA-B\*44:03^HLA-DRB3\*01:01+HLA-DRB3\*01:01^HLA-DRB1\*15:01+HLA-DRB1\*15:01^HLA-DQA1\*01:02+HLA-DQA1\*01:02^HLA-DQB1\*06:02+HLA-DQB1\*06:02^HLA-DPA1\*01:03+HLA-DPA1\*01:03^HLA-DPB1\*03:01+HLA-DPB1\*04:01 |

```
# Step 5: Calculate relevant HCT matches
HCT_table$results <- HLA_match_summary_HCT(HCT_table$recip_data, HCT_table$donor_data, match_grade = "Xof10")

# Step 6: View results
HCT_table$results # Output = 0
```

## License

This project is licensed under the GNU General Public License v3.0. See
the [LICENSE](LICENSE) file for details.

</div>

</div>
