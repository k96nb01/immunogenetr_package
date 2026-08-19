## R CMD check results

0 errors | 0 warnings | 1 note (local Windows only, an artifact of the check machinery; explained below)

The local Windows check shows one NOTE at "checking for non-standard things in the check directory": a directory literally named `'NULL'`. This is an artifact of the R 4.6.1 check machinery on Windows, not of the package: `tools:::setRlibs()` passes the sh-quoted value `R_LIBS_USER='NULL'` unstripped to Rterm.exe, which creates the user library directory at startup. It reproduces with an empty package and does not appear on any other test platform.

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
