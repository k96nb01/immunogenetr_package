# Probe 3: consuming variant with G/P in the bare arm (NB leaning 2026-08-14).
# Match text = the full allele as it appears in the GL String, always.
suppressMessages(library(stringr))

boundary <- "(\\?|\\^|\\||\\+|\\~|/|:|$)"
consuming <- function(a) {
  m <- str_match(a, "^(.*\\d)([NQLSCAGP])$")
  ifelse(is.na(m[, 1]),
    str_c(str_escape(a), "(:\\d+)*[NQLSCAGP]?(?=", boundary, ")"),
    str_c(str_escape(m[, 2]), "(:\\d+)*", m[, 3], "(?=", boundary, ")"))
}

cases <- list(
  # seven expression-suffix rows
  c("HLA-A*01:01:03N",  "HLA-A*01:01",  TRUE),  c("HLA-A*01:01N",   "HLA-A*01:01",  TRUE),
  c("HLA-A*01:01:03N",  "HLA-A*01:01N", TRUE),  c("HLA-A*01:01N",   "HLA-A*01:01N", TRUE),
  c("HLA-A*01:01:03",   "HLA-A*01:01N", FALSE), c("HLA-A*01:010:01","HLA-A*01:01",  FALSE),
  c("HLA-A*01:01:03Q",  "HLA-A*01:01N", FALSE),
  # G/P rows (revised semantics)
  c("HLA-A*01:01:01G",  "HLA-A*01:01:01", TRUE), c("HLA-A*01:01:01G", "HLA-A*01:01",  TRUE),
  c("HLA-A*01:01G",     "HLA-A*01:01",    TRUE), c("HLA-A*24:02P",    "HLA-A*24:02",  TRUE),
  c("HLA-A*01:010G",    "HLA-A*01:01",    FALSE),c("HLA-A*01:01:01G", "HLA-A*01:01G", TRUE),
  c("HLA-A*01:01:01",   "HLA-A*01:01:01G",FALSE),c("HLA-A*24:02",     "HLA-A*24:02P", FALSE),
  c("HLA-A*01:01:01G",  "HLA-A*01:01P",   FALSE)
)
ok <- TRUE
for (cs in cases) {
  got <- str_detect(cs[[1]], consuming(cs[[2]]))
  if (got != as.logical(cs[[3]])) { ok <- FALSE
    cat("MISMATCH:", cs[[1]], "~", cs[[2]], "expected", cs[[3]], "got", got, "\n") }
}
if (ok) cat("detect: all", length(cases), "rows as expected\n") else cat("detect: FAILURES above\n")

cat("\n--- str_extract: always the full allele found ---\n")
GL <- "HLA-A*01:01:01+HLA-A*02:02:02N"
cat("HLA-A*01:01   ->", str_extract(GL, consuming("HLA-A*01:01")), "\n")
cat("HLA-A*02:02N  ->", str_extract(GL, consuming("HLA-A*02:02N")), "\n")
cat("HLA-A*01:01 on ...:01G ->", str_extract("HLA-A*01:01:01G+HLA-B*07:02", consuming("HLA-A*01:01")), "\n")
cat("exact match   ->", str_extract("HLA-A*01:01", consuming("HLA-A*01:01")), "\n")

cat("\n--- str_replace: clean everywhere ---\n")
cat(str_replace("HLA-A*01:01N+HLA-A*02:01",    consuming("HLA-A*01:01"),  "XXX"), "\n")
cat(str_replace("HLA-A*01:01:02+HLA-A*02:01",  consuming("HLA-A*01:01"),  "XXX"), "\n")
cat(str_replace("HLA-A*01:01:02N+HLA-A*02:01", consuming("HLA-A*01:01N"), "XXX"), "\n")
cat(str_replace("HLA-A*01:01:01G+HLA-A*02:01", consuming("HLA-A*01:01G"), "XXX"), "\n")
