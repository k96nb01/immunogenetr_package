pkgname <- "immunogenetr"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
base::assign(".ExTimings", "immunogenetr-Ex.timings", pos = 'CheckExEnv')
base::cat("name\tuser\tsystem\telapsed\n", file=base::get(".ExTimings", pos = 'CheckExEnv'))
base::assign(".format_ptime",
function(x) {
  if(!is.na(x[4L])) x[1L] <- x[1L] + x[4L]
  if(!is.na(x[5L])) x[2L] <- x[2L] + x[5L]
  options(OutDec = '.')
  format(x[1L:3L], digits = 7L)
},
pos = 'CheckExEnv')

### * </HEADER>
library('immunogenetr')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("GLstring_expand_longer")
### * GLstring_expand_longer

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_expand_longer
### Title: GLstring_expand_longer
### Aliases: GLstring_expand_longer

### ** Examples

file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
result <- GLstring_expand_longer(GL_string[1])
print(result)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_expand_longer", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("GLstring_gene_copies_combine")
### * GLstring_gene_copies_combine

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_gene_copies_combine
### Title: GLstring_gene_copies_combine
### Aliases: GLstring_gene_copies_combine

### ** Examples

library(dplyr)
HLA_typing_1 %>%
mutate(across(A1:B2, ~HLA_prefix_add(.))) %>%
GLstring_gene_copies_combine(c(A1:B2), sample_column = patient)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_gene_copies_combine", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("GLstring_genes")
### * GLstring_genes

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_genes
### Title: GLstring_genes
### Aliases: GLstring_genes

### ** Examples


file <- HLA_typing_1[, -1]
GL_string <- data.frame('GL_string' = HLA_columns_to_GLstring (
  file, HLA_typing_columns = everything()))
GL_string <- GL_string[1, , drop = FALSE]  # When considering first patient
result <- GLstring_genes(GL_string, "GL_string")
print(result)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_genes", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("GLstring_genes_expanded")
### * GLstring_genes_expanded

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_genes_expanded
### Title: GLstring_genes_expanded
### Aliases: GLstring_genes_expanded

### ** Examples


file <- HLA_typing_1[, -1]
GL_string <- data.frame('GL_string' = HLA_columns_to_GLstring (
  file, HLA_typing_columns = everything()))
GL_string <- GL_string[1, , drop = FALSE]  # When considering first patient
result <- GLstring_genes_expanded(GL_string, "GL_string")
print(result)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_genes_expanded", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("GLstring_genotype_ambiguity")
### * GLstring_genotype_ambiguity

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_genotype_ambiguity
### Title: GLstring_genotype_ambiguity
### Aliases: GLstring_genotype_ambiguity

### ** Examples

HLA_type <- data.frame(
  sample = c("sample1", "sample2"),
  HLA_A = c("A*01:01+A*68:01|A*01:02+A*68:55|A*01:99+A*68:66", "A*02:01+A*03:01|A*02:02+A*03:03"),
  HLA_B = c("B*07:02+B*58:01|B*07:03+B*58:09", "B*08:01+B*15:01|B*08:02+B*15:17"),
  stringsAsFactors = FALSE
)

GLstring_genotype_ambiguity(HLA_type, columns = c("HLA_A", "HLA_B"), keep_ambiguities = TRUE)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_genotype_ambiguity", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("GLstring_regex")
### * GLstring_regex

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_regex
### Title: GLstring_regex
### Aliases: GLstring_regex

### ** Examples

allele <- "HLA-A*02:01"
GLstring_regex(allele)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_regex", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_column_repair")
### * HLA_column_repair

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_column_repair
### Title: HLA_column_repair
### Aliases: HLA_column_repair

### ** Examples

HLA_type <- data.frame(
  "HLA-A*" = c("01:01", "02:01"),
  "HLA-B*" = c("07:02", "08:01"),
  "HLA-C*" = c("03:04", "04:01"),
  stringsAsFactors = FALSE
)

HLA_column_repair(HLA_type, format = "tidyverse")




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_column_repair", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_columns_to_GLstring")
### * HLA_columns_to_GLstring

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_columns_to_GLstring
### Title: HLA_columns_to_GLstring
### Aliases: HLA_columns_to_GLstring

### ** Examples

#
typing_table <- data.frame(
  patient = c("patient1", "patient2", "patient3"),
  mA1cd = c("A*01:01", "A*02:01", "A*03:01"),
  mA2cd = c("A*11:01", "blank", "A*26:01"),
  mB1cd = c("B*07:02", "B*08:01", "B*15:01"),
  mB2cd = c("B*44:02", "B*40:01", "-"),
  mC1cd = c("C*03:04", "C*04:01", "C*05:01"),
  mC2cd = c("C*07:01", "C*07:02", "C*08:01"),
  stringsAsFactors = FALSE
)

print(typing_table$GL_string <- HLA_columns_to_GLstring(typing_table,
  HLA_typing_columns =
    c("mA1cd", "mA2cd", "mB1cd", "mB2cd", "mC1cd", "mC2cd"),
  prefix_to_remove = "m", suffix_to_remove = "cd"
))

# Can also be used on wild-caught data
file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_columns_to_GLstring", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_match_number")
### * HLA_match_number

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_match_number
### Title: HLA_match_number
### Aliases: HLA_match_number

### ** Examples


file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-B")

# Calculate mismatch numbers (Host vs. Graft)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")

# Calculate mismatch numbers (Graft vs. Host)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")

# Calculate mismatch numbers (Bidirectional)
HLA_match_number(GL_string_recip, GL_string_donor,
  loci,
  direction = "bidirectional"
)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_match_number", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_match_summary_HCT")
### * HLA_match_summary_HCT

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_match_summary_HCT
### Title: HLA_match_summary_HCT
### Aliases: HLA_match_summary_HCT

### ** Examples

# Example recipient and donor GL strings
file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

# Calculate mismatch numbers
HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
  direction = "bidirectional", match_grade = "Xof8"
)






base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_match_summary_HCT", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_mismatch_base")
### * HLA_mismatch_base

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_mismatch_base
### Title: HLA_mismatch_base
### Aliases: HLA_mismatch_base

### ** Examples

file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
mismatches <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)

# Output
# "HLA-A=HLA-A*02:01+HLA-A*11:05, HLA-DR51/52/53=NA, HLA-DPB1=NA"






base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_mismatch_base", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_mismatch_logical")
### * HLA_mismatch_logical

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_mismatch_logical
### Title: HLA_mismatch_logical
### Aliases: HLA_mismatch_logical

### ** Examples


file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
mismatches <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)

# Output
# "HLA-A=TRUE"




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_mismatch_logical", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_mismatch_number")
### * HLA_mismatch_number

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_mismatch_number
### Title: HLA_mismatch_number
### Aliases: HLA_mismatch_number

### ** Examples


file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")

# Calculate mismatch numbers (Host vs. Graft)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")

# Calculate mismatch numbers (Graft vs. Host)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")

# Calculate mismatch numbers (Bidirectional)
HLA_mismatch_number(GL_string_recip, GL_string_donor,
  loci,
  direction = "bidirectional"
)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_mismatch_number", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_mismatched_alleles")
### * HLA_mismatched_alleles

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_mismatched_alleles
### Title: HLA_mismatched_alleles
### Aliases: HLA_mismatched_alleles

### ** Examples

file <- HLA_typing_1[, -1]
GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())

GL_string_recip <- GL_string[1]
GL_string_donor <- GL_string[2]

loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
mismatches <- HLA_mismatched_alleles(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)

# Output
# "HLA-A:HLA-A*02:01+HLA-A*11:05, HLA-DR51/52/53:NA, HLA-DRB3/4/5:HLA-DRB3*01:03, HLA-DPB1:NA"




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_mismatched_alleles", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_prefix_add")
### * HLA_prefix_add

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_prefix_add
### Title: HLA_prefix_add
### Aliases: HLA_prefix_add

### ** Examples


file <- HLA_typing_1[, -1]

# Add "HLA-" prefix to columns A1 and A2
file$A1 <- HLA_prefix_add(file$A1, "HLA-")
file$A2 <- HLA_prefix_add(file$A2, "HLA-")




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_prefix_add", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_prefix_remove")
### * HLA_prefix_remove

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_prefix_remove
### Title: HLA_prefix_remove
### Aliases: HLA_prefix_remove

### ** Examples

df <- data.frame(
  A1 = c("HLA-A2", "A2", "A*11:01", "A66", "HLA-DRB3*15:01"),
  A2 = c("HLA-A1", "A1", "A*02:01", "A68", "HLA-DRB4*14:01"),
  stringsAsFactors = FALSE
)

df <- HLA_prefix_remove(df)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_prefix_remove", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_truncate")
### * HLA_truncate

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_truncate
### Title: HLA_truncate
### Aliases: HLA_truncate

### ** Examples


file <- Haplotype_frequencies
file$`HLA-A` <- HLA_prefix_add(file$`HLA-A`, "HLA-")
file$`HLA-A` <- sapply(file$`HLA-A`, HLA_truncate)
print(file$`HLA-A`)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_truncate", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_validate")
### * HLA_validate

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_validate
### Title: HLA_validate
### Aliases: HLA_validate

### ** Examples

HLA_validate("HLA-A2")
HLA_validate("A*02:01:01:01N")
HLA_validate("A*02:01:01N")
HLA_validate("HLA-DRB1*02:03novel")
HLA_validate("HLA-DQB1*03:01v")
HLA_validate("HLA-DRB1*02:03P")
HLA_validate("HLA-DPB1*04:01:01G")
HLA_validate("2")
HLA_validate(2)
HLA_validate("B27")
HLA_validate("A*010101")
HLA_validate("-")
HLA_validate("blank")




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_validate", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("ambiguity_table_to_GLstring")
### * ambiguity_table_to_GLstring

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: ambiguity_table_to_GLstring
### Title: ambiguity_table_to_GLstring
### Aliases: ambiguity_table_to_GLstring

### ** Examples

# Example data frame input
data <- tibble::tribble(
  ~value, ~entry, ~possible_gene_location,
  ~locus, ~genotype_ambiguity, ~genotype, ~haplotype, ~allele,
  "HLA-A*01:01:01:01", 1, 1,
  1, 1, 1, 1, 1,
  "HLA-A*01:02", 1, 1,
  1, 1, 1, 1, 2,
  "HLA-A*01:03", 1, 1,
  1, 1, 1, 1, 3,
  "HLA-A*01:95", 1, 1,
  1, 1, 1, 1, 4,
  "HLA-A*24:02:01:01", 1, 1,
  1, 1, 2, 1, 1,
  "HLA-A*01:01:01:01", 1, 1,
  1, 2, 1, 1, 1,
  "HLA-A*01:03", 1, 1,
  1, 2, 1, 1, 2,
  "HLA-A*24:03:01:01", 1, 1,
  1, 2, 2, 1, 1,
  "HLA-B*07:01:01", 1, 1,
  2, 1, 1, 1, 1,
  "B*15:01:01", 1, 1,
  2, 1, 2, 1, 1,
  "B*15:02:01", 1, 1,
  2, 1, 2, 1, 2,
  "B*07:03", 1, 1,
  2, 2, 1, 1, 1,
  "B*15:99:01", 1, 1,
  2, 2, 2, 1, 1,
  "HLA-DRB1*03:01:02", 1, 1,
  3, 1, 1, 1, 1,
  "HLA-DRB5*01:01:01", 1, 1,
  3, 1, 1, 2, 1,
  "HLA-KIR2DL5A*0010101", 1, 1,
  3, 1, 2, 1, 1,
  "HLA-KIR2DL5A*0010201", 1, 1,
  3, 1, 3, 1, 1,
  "HLA-KIR2DL5B*0010201", 1, 2,
  1, 1, 1, 1, 1,
  "HLA-KIR2DL5B*0010301", 1, 2,
  1, 1, 2, 1, 1
)

ambiguity_table_to_GLstring(data)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("ambiguity_table_to_GLstring", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("read_HML")
### * read_HML

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: read_HML
### Title: read_HML
### Aliases: read_HML

### ** Examples

HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")
HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

read_HML(HML_1)
read_HML(HML_2)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("read_HML", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
