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

GL_string <- "HLA-A*01:01:01:01/HLA-A*01:02/HLA-A*01:03/HLA-A
  *01:95+HLA-A*24:02:01:01|HLA-A*01:01:01:01/HLA-A*01:03+HLA-A*24:03:01:01
  ^HLA-B*07:01:01+B*15:01:01/B*15:02:01|B*07:03+B*15:99:01^HLA-DRB1*03:01:02
  ~HLA-DRB5*01:01:01+HLA-KIR2DL5A*0010101+HLA-KIR2DL5A*0010201?
  HLA-KIR2DL5B*0010201+HLA-KIR2DL5B*0010301"
result <- GLstring_expand_longer(GL_string)
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

HLA_type <- data.frame(
  sample = c("sample1", "sample2"),
  HLA_A1 = c("HLA-A*01:01", "HLA-A*02:01"),
  HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
  stringsAsFactors = FALSE
)
GLstring_gene_copies_combine(HLA_type, columns = c("HLA_A1", "HLA_A2"))




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

table <- data.frame(
  GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^HLA-B*
  08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01",
  stringsAsFactors = FALSE
)
GLstring_genes(table, "GL_string")




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

table <- data.frame(
GL_string = "HLA-A*29:02+HLA-A*30:02^HLA-C*06:02+HLA-C*07:01^
HLA-B*08:01+HLA-B*13:02^HLA-DRB4*01:03+HLA-DRB4*01:03^HLA-DRB1*04:01+HLA-DRB1*07:01",
stringsAsFactors = FALSE
)

GLstring_genes_expanded(table, "GL_string")




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

typing_table$GL_string <- HLA_columns_to_GLstring(typing_table, HLA_typing_columns =
c("mA1cd", "mA2cd", "mB1cd", "mB2cd", "mC1cd", "mC2cd"),
prefix_to_remove = "m", suffix_to_remove = "cd")




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

# Example recipient and donor GL strings
GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02"
loci <- c("HLA-A", "HLA-B")

# Calculate mismatch numbers (Host vs. Graft)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")

# Calculate mismatch numbers (Graft vs. Host)
HLA_match_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")

# Calculate mismatch numbers (Bidirectional)
HLA_match_number(GL_string_recip, GL_string_donor,
loci, direction = "bidirectional")




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
GL_string_recip <- "HLA-A*29:02^HLA-C*06:02+HLA-C*07:01^HLA-B*08:01+HLA-B*13:02
^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"
GL_string_donor <- "HLA-A*02:01+HLA-A*29:02^HLA-C*06:01+HLA-C*07:02^
HLA-B*08:01+HLA-B*13:03^HLA-DRB1*04:01+HLA-DRB1*07:01^HLA-DQB1*02:02+HLA-DQB1*03:02"

# Calculate mismatch numbers
HLA_match_summary_HCT(GL_string_recip, GL_string_donor,
direction = "bidirectional", match_grade = "Xof8")




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

GL_string_recip <- "HLA-A2+HLA-A68^HLA-Cw1+HLA-Cw17^HLA-DR1+HLA-DR17^HLA-DR52
^HLA-DPB1*04:01"
GL_string_donor <- "HLA-A3+HLA-A69^HLA-Cw10+HLA-Cw9^HLA-DR4+HLA-DR17^HLA-DR52
+HLA-DR53^HLA-DPB1*04:01+HLA-DPB1*04:02"
loci <- c("HLA-A", "HLA-Cw", "HLA-DR51/52/53", "HLA-DPB1")
mismatches <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)

# Output
# "HLA-A=HLA-A3+HLA-A69, HLA-Cw=HLA-Cw10+HLA-Cw9, HLA-DR51/52/53=HLA-DR53, HLA-DPB1=HLA-DPB1*04:02"




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

# Example recipient and donor GL strings
GL_string_recip <- "HLA-A*03:01+HLA-A*74:01^HLA-DRB3*03:01^HLA-DRB5*02:21"
GL_string_donor <- "HLA-A*03:02+HLA-A*20:01^HLA-DRB3*03:01"

# Check if there are mismatches for HLA-A (Graft vs. Host)
HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci =
"HLA-A", direction = "GvH")




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

# Example recipient and donor GL strings
GL_string_recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02"
loci <- c("HLA-A", "HLA-B")

# Calculate mismatch numbers (Host vs. Graft)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")

# Calculate mismatch numbers (Graft vs. Host)
HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")

# Calculate mismatch numbers (Bidirectional)
HLA_mismatch_number(GL_string_recip, GL_string_donor,
loci, direction = "bidirectional")




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

GL_string_recip <- "HLA-A2+HLA-A68^HLA-Cw1+HLA-Cw17^HLA-DR1+HLA-DR17^HLA-DR52
^HLA-DPB1*04:01"
GL_string_donor <- "HLA-A3+HLA-A69^HLA-Cw10+HLA-Cw9^HLA-DR4+HLA-DR17^HLA-DR52
+HLA-DR53^HLA-DPB1*04:01+HLA-DPB1*04:02"
loci <- c("HLA-A", "HLA-Cw", "HLA-DR51/52/53", "HLA-DPB1")
mismatches <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatches)

# Output
# "HLA-A=HLA-A3+HLA-A69, HLA-Cw=HLA-Cw10+HLA-Cw9, HLA-DR51/52/53=HLA-DR53, HLA-DPB1=HLA-DPB1*04:02"




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

df <- data.frame(
  A1 = c("01:01", "02:01"),
  A2 = c("03:01", "11:01"),
  B1 = c("07:02", "08:01"),
  B2 = c("15:01", "44:02"),
  stringsAsFactors = FALSE
)

# Add "HLA-A*" prefix to columns A1 and A2
df$A1 <- HLA_prefix_add(df$A1, "HLA-A*")
df$A2 <- HLA_prefix_add(df$A2, "HLA-A*")




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

typing <- "A*01:01:01:02N"
HLA_truncate(typing) # "A*01:01"




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
data <- data.frame(
  value = c(
    "HLA-A*01:01:01:01", "HLA-A*01:02", "HLA-A*01:03", "HLA-A*01:95",
    "HLA-A*24:02:01:01", "HLA-A*01:01:01:01", "HLA-A*01:03",
    "HLA-A*24:03:01:01", "HLA-B*07:01:01", "B*15:01:01"
  ),
  possible_gene_location = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  locus = c("HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A",
    "HLA-A", "HLA-B", "HLA-B"),
  genotype_ambiguity = c(1, 1, 1, 1, 1, 2, 2, 2, 1, 1),
  genotype = c(1, 1, 1, 1, 2, 1, 1, 2, 1, 2),
  haplotype = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  entry = c(1, 2, 3, 4, 1, 1, 2, 1, 1, 1),
  stringsAsFactors = FALSE
)
result <- ambiguity_table_to_GLstring(data)
print(result)




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

read_HML("../inst/extdata/HML_1.hml")
read_HML("../inst/extdata/hml_2.hml")




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
