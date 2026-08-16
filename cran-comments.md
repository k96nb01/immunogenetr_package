## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments
- local Windows 11 (R 4.6.1)
- win-builder R-devel
- GitHub Actions: macOS-latest (release), windows-latest (release), ubuntu-latest (devel, release, oldrel-1)
- R-hub: gcc16, donttest, nosuggests

## R-hub notes

The `nosuggests` platform reports an ERROR at "checking re-building of vignette outputs":

    Error: processing vignette 'immunogenetr.Rmd' failed with diagnostics:
    there is no package called 'rmarkdown'

This is the standard interaction between R-hub's `nosuggests` platform and vignettes built with the `rmarkdown` engine. CRAN's own incoming check runs with `_R_CHECK_FORCE_SUGGESTS_=false`, which downgrades this case to a NOTE. The `gcc16` and `donttest` platforms pass cleanly.

## Downstream dependencies
There are currently no downstream dependencies for this package.
