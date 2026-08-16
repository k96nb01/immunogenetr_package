# Probe: issue #43 floating-suffix design, extended to G/P groups.
# Read-only; tests candidate patterns built inline (no package changes).
suppressMessages(library(stringr))

boundary <- "(\\?|\\^|\\||\\+|\\~|/|:|$)"

# Current (1.4.0 / dev) pattern
current <- function(a) str_c(str_escape(a), "(?=", boundary, ")")

# Floating design (notes' shape):
#   bare query      -> query(?=[NQLSCA]?boundary)         (suffix stays in lookahead)
#   suffixed query  -> base(:\d+)*SUFFIX(?=boundary)      (fields + suffix consumed)
#   G/P query       -> base(:\d+)*[GP](?=boundary)        (same floating shape)
#   bare query does NOT get G/P in the optional class.
floating <- function(a) {
  m <- str_match(a, "^(.*\\d)([NQLSCAGP])$")
  ifelse(is.na(m[, 1]),
    str_c(str_escape(a), "(?=[NQLSCA]?", boundary, ")"),
    str_c(str_escape(m[, 2]), "(:\\d+)*", m[, 3], "(?=", boundary, ")"))
}

# Alternative for the replacement discussion: same detect semantics, but the
# bare-query arm also CONSUMES trailing fields + suffix instead of looking ahead.
consuming <- function(a) {
  m <- str_match(a, "^(.*\\d)([NQLSCAGP])$")
  ifelse(is.na(m[, 1]),
    str_c(str_escape(a), "(:\\d+)*[NQLSCA]?(?=", boundary, ")"),
    str_c(str_escape(m[, 2]), "(:\\d+)*", m[, 3], "(?=", boundary, ")"))
}

cases <- list(
  # --- the seven expression-suffix rows from the notes ---
  c("HLA-A*01:01:03N",  "HLA-A*01:01"),
  c("HLA-A*01:01N",     "HLA-A*01:01"),
  c("HLA-A*01:01:03N",  "HLA-A*01:01N"),
  c("HLA-A*01:01N",     "HLA-A*01:01N"),
  c("HLA-A*01:01:03",   "HLA-A*01:01N"),
  c("HLA-A*01:010:01",  "HLA-A*01:01"),
  c("HLA-A*01:01:03Q",  "HLA-A*01:01N"),
  # --- G/P rows ---
  c("HLA-A*01:01:01G",  "HLA-A*01:01G"),   # truncated G query finds its source
  c("HLA-A*01:01:01G",  "HLA-A*01:01"),    # bare query vs 3-field G name
  c("HLA-A*01:01G",     "HLA-A*01:01"),    # bare query vs truncated G name
  c("HLA-A*01:01:01G",  "HLA-A*01:01P"),   # G must not answer P
  c("HLA-A*24:02P",     "HLA-A*24:02P"),   # P exact
  c("HLA-A*24:02P",     "HLA-A*24:02"),    # bare query vs P name
  c("HLA-A*01:010:01G", "HLA-A*01:01G"),   # over-match control on G arm
  # --- mid-string (not end-of-string) ---
  c("HLA-A*01:01:01G+HLA-A*02:01", "HLA-A*01:01G"),
  c("HLA-A*01:01N+HLA-A*02:01",    "HLA-A*01:01"),
  c("HLA-A*01:01:02N+HLA-A*02:01", "HLA-A*01:01N")
)

cat(sprintf("%-28s %-15s %-8s %-9s %-9s\n", "GL String", "query", "current", "floating", "consuming"))
for (cs in cases) {
  cat(sprintf("%-28s %-15s %-8s %-9s %-9s\n", cs[1], cs[2],
    str_detect(cs[1], current(cs[2])),
    str_detect(cs[1], floating(cs[2])),
    str_detect(cs[1], consuming(cs[2]))))
}

cat("\n--- what the match text is (str_extract) ---\n")
ext <- list(
  c("HLA-A*01:01N",     "HLA-A*01:01"),   # bare query, suffixed allele
  c("HLA-A*01:01:02",   "HLA-A*01:01"),   # bare query, deeper allele
  c("HLA-A*01:01:02N",  "HLA-A*01:01N"),  # suffixed query, deeper allele
  c("HLA-A*01:01:01G",  "HLA-A*01:01G")   # G query, full G name
)
cat(sprintf("%-18s %-15s %-16s %-16s %-16s\n", "GL String", "query", "current", "floating", "consuming"))
for (cs in ext) {
  cat(sprintf("%-18s %-15s %-16s %-16s %-16s\n", cs[1], cs[2],
    str_extract(cs[1], current(cs[2])),
    str_extract(cs[1], floating(cs[2])),
    str_extract(cs[1], consuming(cs[2]))))
}

cat("\n--- str_replace consequences ---\n")
rep <- list(
  c("HLA-A*01:01N+HLA-A*02:01",    "HLA-A*01:01"),   # dangling-suffix hazard
  c("HLA-A*01:01:02+HLA-A*02:01",  "HLA-A*01:01"),   # dangling-fields (pre-existing)
  c("HLA-A*01:01:02N+HLA-A*02:01", "HLA-A*01:01N"),  # suffixed query
  c("HLA-A*01:01:01G+HLA-A*02:01", "HLA-A*01:01G")   # G query
)
cat(sprintf("%-28s %-15s %-28s %-28s %-28s\n", "GL String", "query", "current", "floating", "consuming"))
for (cs in rep) {
  cat(sprintf("%-28s %-15s %-28s %-28s %-28s\n", cs[1], cs[2],
    str_replace(cs[1], current(cs[2]), "XXX"),
    str_replace(cs[1], floating(cs[2]), "XXX"),
    str_replace(cs[1], consuming(cs[2]), "XXX")))
}
