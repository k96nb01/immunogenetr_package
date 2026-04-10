## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

* Added `scope` parameter to `HLA_match_summary_HCT` with options `"locus"` (default) and `"genotype"`. When `scope = "genotype"` and `direction = "bidirectional"`, the function calculates GvH and HvG match summaries separately and returns the maximum of the two totals, rather than taking the minimum match at each locus before summing.

* Simplified `HLA_match_summary_HCT` internals: replaced the tibble parsing pipeline with `str_extract_all()` and `map_int()` for summing per-locus match counts.

