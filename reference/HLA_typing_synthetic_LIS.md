# Synthetic clinical-laboratory HLA typing table (HistoTrac "Patient" layout).

A larger, deliberately messy synthetic data set patterned on a real
laboratory information system "Patient" table, with one individual per
row. It is intended as realistic development and test data for
[`HLA_columns_to_GLstring`](https://immunogenetr.org/reference/HLA_columns_to_GLstring.md)
and related functions: the typing columns exercise the full range of
wild-caught notation, including serologic values with and without a
leading "w" (e.g. `"w4"`, `"4"`), leading zeros (`"06"`), bare-asterisk
molecular shorthand (`"*17"`), colon-delimited molecular alleles
(`"02:01"`), blanks, and `NA`s. Both serologic (`A1Cd:dq2cd`) and
molecular (`mA1Cd:mDPB12cd`) typings are present for the HLA-A, B, Bw,
C, DRB1, DRB3/4/5, DQB1, DQA1, DPB1 and DPA1 loci.

## Usage

``` r
data(HLA_typing_synthetic_LIS)
```

## Format

A tibble with 63 rows and 53 columns:

- PatientId, UNOSId, HospitalID, PhysicianID:

  Synthetic record identifiers.

- firstnm, lastnm, DOB:

  Synthetic demographics (donors carry their donor ID in `firstnm`).

- categoryCd, RaceCd, GenderCd, ABOCd, PatientTypeCd, StatusCd:

  Synthetic categorical fields.

- A1Cd:dq2cd:

  Serologic HLA typing (A, B, Bw, Cw, DR, DRw, DQ), as character.

- mA1Cd:mDPB12cd:

  Molecular HLA typing (A, B, C, DRB1, DRB3/4/5, DQA1, DQB1, DPA1,
  DPB1), as character.

- UNOSCPRAAmt:

  Synthetic calculated PRA value.

- UnacceptAntigenTxt, ModerateRiskAntibodyTxt, UNOSUnacceptAntigenTxt:

  Synthetic antibody text fields.

## Source

Synthetic data from Nicholas K. Brown, patterned on a clinical
laboratory information system.

## Details

Note that the molecular (`m...`) columns deliberately contain a *mix* of
true molecular values (e.g. `"31:01"`) and serologic values (e.g.
`"w6"`): the source laboratory historically recorded serologic typing in
the molecular columns, so this captures that real-world
mixed-nomenclature-within-a-column case.

All identifiers, names and dates are synthetic.
