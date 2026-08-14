# Probe 4: prefix-optional GLstring_regex (NB question 2026-08-14).
# Design: strip any "HLA-" from the query, emit an optional (HLA-)? prefix,
# and add a LEFT boundary (start-of-string or GL delimiter, via lookbehind).
# The left boundary is what the mandatory prefix was implicitly providing:
# it stops the pattern matching inside a longer locus name (e.g. MICA).
suppressMessages(library(stringr))

right <- "(?=(\\?|\\^|\\||\\+|\\~|/|$))"
left  <- "(?:(?<=[\\?\\^\\|\\+\\~/])|^)"

prefixless <- function(a) {
  base_all <- str_replace(a, "^HLA-", "")
  m <- str_match(base_all, "^(.*\\d)([NQLSCAGP])$")
  ifelse(is.na(m[, 1]),
    str_c(left, "(HLA-)?", str_escape(base_all), "(:\\d+)*[NQLSCAGP]?", right),
    str_c(left, "(HLA-)?", str_escape(m[, 2]), "(:\\d+)*", m[, 3], right))
}

cases <- list(
  # cross-convention matching: query and GL String in either style
  c("HLA-A*02:01:01+HLA-A*68:01", "HLA-A*02:01", TRUE),
  c("A*02:01:01+A*68:01",         "HLA-A*02:01", TRUE),
  c("HLA-A*02:01:01+HLA-A*68:01", "A*02:01",     TRUE),
  c("A*02:01:01+A*68:01",         "A*02:01",     TRUE),
  # left-boundary false-positive controls
  c("MICA*008:01+MICA*002:01",    "A*008:01",    FALSE),  # A must not match inside MICA
  c("MICB*005:02",                "B*005:02",    FALSE),  # B must not match inside MICB
  c("HLA-DQA1*01:01",             "A1*01:01",    FALSE),  # partial locus name
  # over-match and suffix behavior carry over unchanged
  c("A*02:149:01",                "A*02:14",     FALSE),
  c("A*24:09N+A*02:01",           "A*24:09",     TRUE),
  c("A*01:01:03N",                "A*01:01N",    TRUE),
  c("A*01:01:03",                 "A*01:01N",    FALSE),
  c("A*01:01:01G",                "A*01:01G",    TRUE),
  # serologic, both conventions
  c("A2^B27",                     "A2",          TRUE),
  c("A24^B27",                    "A2",          FALSE),
  c("HLA-A2^HLA-B27",             "A2",          TRUE),
  # mid-string with delimiters on the left
  c("B*07:02/A*02:01",            "A*02:01",     TRUE),
  c("B*07:02|A*02:01~C*01:02",    "A*02:01",     TRUE)
)
ok <- TRUE
for (cs in cases) {
  got <- str_detect(cs[[1]], prefixless(cs[[2]]))
  if (got != as.logical(cs[[3]])) { ok <- FALSE
    cat("MISMATCH:", cs[[1]], "~", cs[[2]], "expected", cs[[3]], "got", got, "\n") }
}
if (ok) cat("detect: all", length(cases), "rows as expected\n") else cat("detect: FAILURES above\n")

cat("\n--- match text stays 'as written in the GL String' ---\n")
cat("bare query, prefixed string ->", str_extract("HLA-A*02:01:01+HLA-A*68:01", prefixless("A*02:01")), "\n")
cat("prefixed query, bare string ->", str_extract("A*02:01:01+A*68:01", prefixless("HLA-A*02:01")), "\n")
cat("replace, bare string        ->", str_replace("A*02:01:01+A*68:01", prefixless("HLA-A*02:01"), "XXX"), "\n")
