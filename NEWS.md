# immunogenetr 1.3.0

* Rewrote `HLA_prefix_remove` to skip the GL-string expand-and-reassemble round-trip. The previous implementation expanded each GL string into an ambiguity tibble, ran `str_replace` on it, and reassembled — which was the dominant cost in any pipeline that called `HLA_prefix_remove` per cell. Now four direct regex passes on the GL-string character vector. ~100× faster end-to-end, up to ~420× less memory allocated on 100,000-input workloads. Because many other functions in the package (including `HLA_columns_to_GLstring`) call `HLA_prefix_remove` internally, every downstream caller picks up the speedup for free.

* Rewrote `HLA_columns_to_GLstring` to compute column-level decisions (locus mapping from column name, serologic-name lookup, "always molecular" flag for DQA1/DPA1/DPB1) once per column instead of once per cell, and replaced the two trailing `summarise(str_flatten(...))` passes with vectorised `split` + `paste`. End-to-end ~68× faster at 1000 rows (7.4 s -> 109 ms) and ~200× faster at 10,000 rows (~272 s -> ~1.3 s).

* Rewrote `HLA_mismatch_base` to replace the per-pair `purrr::map2_chr` loop and stringr wrappers with base-R / stringi primitives, hoist invariants out of the per-pair loop, and short-circuit the null-allele regex on alleles that cannot match. ~26× faster at 100 pairs, ~11× faster at 10,000 pairs, and ~1000× less memory allocated on the large workload. Also tuned the residual `unify_locus` / DRB3/4/5 classification / molecular prefix extraction hot spots exposed by the post-merge re-profile.

* Rewrote the four `HLA_mismatch_*` derivatives (`HLA_mismatch_logical`, `HLA_mismatch_number`, `HLA_mismatch_alleles`, `HLA_mismatched_alleles`) to replace the shared `tibble -> separate_longer_delim -> separate_wider_delim -> summarise` post-processing pipeline with direct character-vector ops on an integer mismatch count matrix. 10-50× less memory; 10-15% faster per call (the underlying `HLA_mismatch_base` call now dominates).

* Rewrote `HLA_match_number` and `HLA_match_summary_HCT` to share a new internal helper `hla_mismatch_count_matrix()` that exposes the integer count matrix `HLA_mismatch_number` already builds, skipping the format-and-reparse round-trip through its string output. 15-20% faster end-to-end, 10-21× less memory per call.

* Rewrote `GLstring_expand_longer` to replace the 7-level `tidyr::separate_longer_delim + row_number()` chain with a `stringi::stri_split_fixed` cascade that assembles the output tibble directly from equal-length index vectors. 20-43× faster depending on input size; up to 4× less memory.

* Rewrote `ambiguity_table_to_GLstring` to replace six chained `dplyr::summarise(str_flatten(...))` passes with a single sort-and-paste helper. Subsequent levels of the GL hierarchy skip the redundant sort since the composite index key stays sorted under prefix truncation. 2-13× faster depending on size and the `remove_duplicates` flag.

* Rewrote `HLA_truncate` to replace the `GLstring_expand_longer -> 4x separate_wider_delim -> 4x unite -> ambiguity_table_to_GLstring` pipeline with a vectorised per-allele truncator that flattens all fields across all alleles into a single long vector for regex processing, then collapses per allele in one pass. ~5× faster end-to-end at 1000 alleles.

* Rewrote `GLstring_gene_copies_combine` to replace the `pivot_longer -> mutate(str_extract) -> summarise(str_c) -> pivot_wider -> rename_with` round-trip with a one-pass flat-vector build. ~7× faster at 1000 rows.

* Rewrote `GLstring_genes` to replace `separate_longer_delim -> rename -> mutate(str_extract) -> pivot_wider` with a direct `stringi::stri_split_fixed` + per-locus column build. 2.6-3.7× faster.

* Rewrote `GLstring_genes_expanded` to replace the `pivot_wider(values_fn = list) -> unnest` pipeline with per-row `split` and `bind_rows`. ~5× faster on 100 single-row calls, ~16× less memory. As a side effect, the function now handles multi-row input gracefully; the previous implementation errored on `unnest` when different rows had different allele counts per locus. Single-row semantics — including the intentional recycling of length-1 cells flagged as expected behavior in the test file — are preserved.

* Added `check_molecular_gl_string()` internal validation helper for callers that want to enforce molecular-only GL string inputs (used at API boundaries). Opt-in; not wired into existing functions to preserve compatibility with serologic-input callers.

* Fixed a latent correctness bug in the "missing loci" check in `HLA_mismatch_base` introduced during earlier optimization work. The check silently required a locus to be missing from both recipient and donor before erroring, instead of the original semantics of missing from either side. Restored the original behavior.

* Added a round-trip property test suite (`tests/testthat/test-round_trip.R`) asserting that `ambiguity_table_to_GLstring(GLstring_expand_longer(x)) == x` for a representative pool of GL strings, and that `HLA_prefix_add` / `HLA_prefix_remove` form an inverse pair on raw allele input. Added explicit NA-propagation regression tests for `ambiguity_table_to_GLstring` and `GLstring_genes` covering bugs caught during the rewrite. Added tests for `check_molecular_gl_string`.

* Added `stringi` (>= 1.7.0) as a direct `Imports` dependency. It was previously a transitive dependency via `stringr`; this release uses it directly for `stri_split_fixed`, `stri_startswith_fixed`, `stri_endswith_fixed`, and `stri_extract_first_regex` in the rewritten functions.

* Removed `glue` and `magrittr` from `Imports`. No function in the package uses them directly after these rewrites (`str_glue` calls were replaced with `paste0`/`paste`; `%>%` is still available via `@importFrom dplyr %>%`).

# immunogenetr 1.2.0

* Added `scope` parameter to `HLA_match_summary_HCT` with options `"locus"` (default) and `"genotype"`. When `scope = "genotype"` and `direction = "bidirectional"`, the function calculates GvH and HvG match summaries separately and returns the maximum of the two totals, rather than taking the minimum match at each locus before summing.

* Simplified `HLA_match_summary_HCT` internals: replaced the tibble parsing pipeline with `str_extract_all()` and `map_int()` for summing per-locus match counts.

# immunogenetr 1.1.0

* Internal code quality improvements: fixed typos in internal variable names, corrected test filenames, and cleaned up `globalVariables()` declarations.

* Standardized all error messages to use `cli_abort()` for consistent, informative error reporting across the package. Bumped `cli` dependency to >= 3.0.0.

* Added input validation to all exported functions. Functions now check for NULL, wrong types, and invalid parameter values before processing, providing clear error messages instead of cryptic failures. Added internal validation helper functions (`check_gl_string`, `check_data_frame`, `check_loci`, `check_logical_flag`, `check_homozygous_count`, `check_fields`).

* Added `match.arg()` validation for `match_grade` and `direction` parameters in `HLA_match_summary_HCT`.

* Refactored duplicated matching logic across `HLA_match_summary_HCT`, `HLA_match_number`, `HLA_mismatch_number`, and `HLA_mismatch_logical`. Replaced repeated direction-branching code blocks with parameterized pipelines, significantly reducing code duplication with no changes to behavior.

* Optimized `HLA_mismatch_base`: consolidated duplicated GvH/HvG mismatch calculation into a single parameterized code path, eliminated repeated `strsplit()` calls within the mismatch loop, and extracted duplicated locus-naming logic into a shared helper function.

* Optimized `HLA_mismatch_number` and `HLA_mismatch_logical` to only compute the requested direction(s). Previously both functions always computed GvH and HvG regardless of the requested direction; now HvG, GvH, and SOT requests only compute a single direction, cutting `HLA_mismatch_base` calls in half. Bidirectional requests still compute both as needed. Also extracted duplicated multi-locus table-building code into internal helper functions.

* Expanded test coverage for `HLA_mismatch_logical`, `HLA_match_number`, and `HLA_mismatched_alleles` using the `mismatch_table_2010` and `mismatch_table_2016` consensus reference tables, matching the existing comprehensive table-based tests in `HLA_mismatch_number`.

* Optimized `HLA_columns_to_GLstring`: replaced 16 case-insensitive regex calls for locus detection with a single `tolower()` plus `startsWith()` lookups (~7.5x faster), replaced the serologic name `case_when` with a named vector lookup (~37x faster), and combined multiple `str_detect()` calls for molecular typing detection into single patterns.

* Optimized `HLA_truncate`: replaced four nearly-identical `if/else` blocks for field selection with a parameterized approach using computed `keep_cols`/`drop_cols` vectors, reducing code duplication and improving maintainability.

* Optimized `ambiguity_table_to_GLstring`: extracted a `collapse_level()` helper function to replace six repetitions of the conditional `distinct()` + `summarise()` pattern, significantly reducing code duplication.

* Optimized `GLstring_genotype_ambiguity`: simplified the gene-separator error detection from a multi-step pipeline to a single vectorized check, and combined two separate `str_replace()` + `na_if()` calls into one operation.

* Expanded test coverage for `HLA_column_repair`, `GLstring_genes`, `GLstring_regex`, and `read_HML` with comprehensive tests covering format conversions, parameter combinations, edge cases, input validation, and error handling.

* Fixed `read_HML` to dynamically discover the XML namespace instead of hardcoding the `d1:` prefix. The function now uses `xml_ns()` to detect the namespace from the file, improving compatibility with HML files from different sources.

* Fixed null allele detection regex in `HLA_mismatch_base` to support locus names longer than 4 characters (e.g. `HLA-DRB345`). The lookbehind now allows up to 10 alphanumeric characters after `HLA-`.

* Added a "Getting Started" vignette covering all major workflows: tabular-to-GL-string conversion, locus splitting, mismatch/match calculation, allele name utilities, and HML file reading.

* Added a package-level help page (`?immunogenetr`) organizing all exported functions and datasets by category.

* Added `inst/CITATION` file for the package publication: Coskun & Brown (2026), "Immunogenetr: A comprehensive toolkit for clinical HLA informatics," *Human Immunology*, 87(1):111619. doi:10.1016/j.humimm.2025.111619.

# immunogenetr 1.0.1

* Added a disclaimer to the package for it being for research use only. Added a disclaimer to the help file for `HLA_truncate` to warn users about the ability to make non-WHO-compliant allele names with certain settings. Updated `HLA_mismatch_base` to better handle missing loci at the DRB3/4/5 locus.

# immunogenetr 1.0.0

* Added `HLA_mismatch_alleles` as a synonym of `HLA_mismatched_alleles`. Added minimum versions in DESCRIPTION. Stable release; updated version to 1.0.0.  

# immunogenetr 0.3.1

* Updated `HLA_columns_to_GLstring` to fix issues processing DRB3/4/5 alleles. 

# immunogenetr 0.3.0

* Updated `ambiguity_table_to_GLstring` to remove duplicate entries from an ambiguity table as it is being processed to a GL string. Added this functionality to `HLA_truncate` so that truncated GL strings could optionally remove duplicates. Added `GLstring_to_ambiguity_table` as an alias for `GL_string_expand_longer`. 

# immunogenetr 0.2.0

* Updated `HLA_prefix_add` and `HLA_prefix_remove` to work on all alleles in a GL string. Also added the option of keeping locus designations in `HLA_prefix_remove`.

# immunogenetr 0.1.0

* Initial CRAN submission.
