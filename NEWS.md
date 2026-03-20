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
