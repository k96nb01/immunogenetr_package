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
