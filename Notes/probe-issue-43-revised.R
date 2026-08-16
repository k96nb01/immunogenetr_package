# Probe 2: revised design after NB feedback 2026-08-14.
# Change from probe 1: bare queries SHOULD match G/P names (a G group contains
# the allele in its name), so G and P join the optional class in the bare arm.
suppressMessages(library(stringr))

boundary <- "(\\?|\\^|\\||\\+|\\~|/|:|$)"

# Revised floating: bare arm gets [NQLSCAGP]? in the lookahead (match text = query).
floating <- function(a) {
  m <- str_match(a, "^(.*\\d)([NQLSCAGP])$")
  ifelse(is.na(m[, 1]),
    str_c(str_escape(a), "(?=[NQLSCAGP]?", boundary, ")"),
    str_c(str_escape(m[, 2]), "(:\\d+)*", m[, 3], "(?=", boundary, ")"))
}

cases <- list(
  # G/P rows under the revised bare arm
  c("HLA-A*01:01:01G", "HLA-A*01:01:01"),  # full base query vs G name -> want TRUE
  c("HLA-A*01:01:01G", "HLA-A*01:01"),     # shorter query vs G name   -> want TRUE
  c("HLA-A*01:01G",    "HLA-A*01:01"),     # truncated G name          -> want TRUE now
  c("HLA-A*24:02P",    "HLA-A*24:02"),     # P name                    -> want TRUE now
  c("HLA-A*01:010G",   "HLA-A*01:01"),     # over-match control        -> want FALSE
  c("HLA-A*01:01:01G", "HLA-A*01:01G"),    # truncated G query, floating -> TRUE
  c("HLA-A*01:01:01",  "HLA-A*01:01:01G"), # G query vs bare allele    -> open question (currently FALSE)
  c("HLA-A*24:02",     "HLA-A*24:02P"),    # P query vs bare allele    -> open question (currently FALSE)
  # regression: original seven still hold
  c("HLA-A*01:01N",    "HLA-A*01:01"),
  c("HLA-A*01:01:03N", "HLA-A*01:01N"),
  c("HLA-A*01:01:03",  "HLA-A*01:01N"),
  c("HLA-A*01:010:01", "HLA-A*01:01"),
  c("HLA-A*01:01:03Q", "HLA-A*01:01N")
)
cat(sprintf("%-18s %-16s %-8s\n", "GL String", "query", "floating"))
for (cs in cases) cat(sprintf("%-18s %-16s %-8s\n", cs[1], cs[2], str_detect(cs[1], floating(cs[2]))))

cat("\n--- str_extract under revised floating (NB's two examples + suffixed-deeper) ---\n")
GL <- "HLA-A*01:01:01+HLA-A*02:02:02N"
cat("query HLA-A*01:01   ->", str_extract(GL, floating("HLA-A*01:01")), "\n")
cat("query HLA-A*02:02N  ->", str_extract(GL, floating("HLA-A*02:02N")), "\n")
cat("query HLA-A*02:02:02N (exact) ->", str_extract(GL, floating("HLA-A*02:02:02N")), "\n")
