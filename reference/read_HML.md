# read_HML

Reads the GL strings of HML files and returns a tibble with the full
genotype for each sample.

## Usage

``` r
read_HML(HML_file)
```

## Arguments

- HML_file:

  The path to an HML file.

## Value

A tibble with the sample name and the GL string.

## Examples

``` r
HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")
HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

read_HML(HML_1)
#> # A tibble: 5 × 2
#>   sampleID                          GL_string                                   
#>   <chr>                             <chr>                                       
#> 1 22-03848-HLA-031722-AB-AlloSeq-EP HLA-A*33:03:01:01+HLA-A*34:02:01:01^HLA-B*1…
#> 2 22-03849-HLA-031722-AB-AlloSeq-EP HLA-A*23:01:01:01+HLA-A*30:01:01:01^HLA-B*5…
#> 3 22-03850-HLA-031722-AB-AlloSeq-EP HLA-A*02:01:01:01+HLA-A*02:01:01:01^HLA-B*3…
#> 4 22-03851-HLA-031722-AB-AlloSeq-EP HLA-A*02:01:01:01+HLA-A*23:01:01:01^HLA-B*4…
#> 5 22-03852-HLA-031722-AB-AlloSeq-EP HLA-A*33:01:01:01+HLA-A*33:03:01:01/HLA-A*3…
read_HML(HML_2)
#> # A tibble: 5 × 2
#>   sampleID GL_string                                                            
#>   <chr>    <chr>                                                                
#> 1 22-03848 HLA-A*33:03:01+HLA-A*34:02:01^HLA-B*14:01:01+HLA-B*44:03:02^HLA-C*07…
#> 2 22-03849 HLA-A*23:01:01+HLA-A*30:01:01^HLA-B*53:01:01+HLA-B*81:01:01^HLA-C*06…
#> 3 22-03850 HLA-A*02:01:01+HLA-A*02:01:01^HLA-B*35:01:01+HLA-B*39:10:01^HLA-C*04…
#> 4 22-03851 HLA-A*02:01:01+HLA-A*23:01:01^HLA-B*45:01:01+HLA-B*58:113^HLA-C*07:1…
#> 5 22-03852 HLA-A*33:01:01+HLA-A*33:03:01^HLA-B*14:02:01+HLA-B*35:01:01^HLA-C*04…
```
