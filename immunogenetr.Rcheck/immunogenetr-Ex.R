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
nameEx("GLstring_gene_copies_combine")
### * GLstring_gene_copies_combine

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: GLstring_gene_copies_combine
### Title: GLstring_gene_copies_combine
### Aliases: GLstring_gene_copies_combine

### ** Examples

HLA_type <- tibble(
  sample = c("sample1", "sample2"),
  HLA_A1 = c("HLA-A*01:01", "HLA-A*02:01"),
  HLA_A2 = c("HLA-A*01:02", "HLA-A*02:02"),
  stringsAsFactors = FALSE
  )

HLA_type %>% GLstring_gene_copies_combine(columns = c("HLA_A1", "HLA_A2"))




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("GLstring_gene_copies_combine", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("HLA_column_repair")
### * HLA_column_repair

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: HLA_column_repair
### Title: HLA_column_repair
### Aliases: HLA_column_repair

### ** Examples

HLA_type <- tibble(
"HLA-A*" = c("01:01", "02:01"),
"HLA-B*" = c("07:02", "08:01"),
"HLA-C*" = c("03:04", "04:01")
)
HLA_type %>% HLA_column_repair(format = "tidyverse")




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_column_repair", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
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
has_mismatch <- HLA_mismatch_logical(GL_string_recip, GL_string_donor, loci =
"HLA-A", direction = "GvH")
print(has_mismatch)
# Output: TRUE




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
mismatch_count_HvG <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "HvG")
print(mismatch_count_HvG)

# Calculate mismatch numbers (Graft vs. Host)
mismatch_count_GvH <- HLA_mismatch_number(GL_string_recip, GL_string_donor, loci, direction = "GvH")
print(mismatch_count_GvH)

# Calculate mismatch numbers (Bidirectional)
mismatch_count_bidirectional <- HLA_mismatch_number(GL_string_recip, GL_string_donor,
loci, direction = "bidirectional")
print(mismatch_count_bidirectional)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_mismatch_number", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
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

# Add HLA- prefix to columns A1 and A2
df %>% HLA_prefix_add(columns = c("A1", "A2"))




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("HLA_prefix_add", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
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
data <- tibble(
  value = c(
    "HLA-A*01:01:01:01", "HLA-A*01:02", "HLA-A*01:03", "HLA-A*01:95",
    "HLA-A*24:02:01:01", "HLA-A*01:01:01:01", "HLA-A*01:03",
    "HLA-A*24:03:01:01", "HLA-B*07:01:01", "B*15:01:01"),
  possible_gene_location = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  locus = c("HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A", "HLA-A",
    "HLA-A", "HLA-B", "HLA-B"),
  genotype_ambiguity = c(1, 1, 1, 1, 1, 2, 2, 2, 1, 1),
  genotype = c(1, 1, 1, 1, 2, 1, 1, 2, 1, 2),
  haplotype = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  allele = c(1, 2, 3, 4, 1, 1, 2, 1, 1, 1)
)
result <- ambiguity_table_to_GLstring(data)
print(result)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("ambiguity_table_to_GLstring", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
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
