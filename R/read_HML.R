#' @title read_HML
#'
#' @description Reads the GL strings of HML files and returns a tibble with
#' the full genotype for each sample.
#'
#' @param HML_file The path to an HML file.
#'
#' @return A tibble with the sample name and the GL string.
#'
#' @examples
#' read_HML("HML_1.hml")
#' read_HML("HML_2.hml")
#'
#' @export
#'
#' @importFrom xml2 read_xml
#' @importFrom dplyr %>%
#' @importFrom xml2 xml_find_all
#' @importFrom purrr map
#' @importFrom xml2 xml_attr
#' @importFrom xml2 xml_find_all
#' @importFrom xml2 xml_text
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom dplyr mutate
#' @importFrom stringr str_extract
#' @importFrom dplyr distinct
#' @importFrom tidyr pivot_wider
#' @importFrom tidyr unite


read_HML <- function(HML_file){
  # Load the HML file
  HML <- read_xml(HML_file)

  # Filter for all the children in the HML file that represent a sample
  samples <-  HML %>%
    xml_find_all( ".//d1:sample")

  # Get sample number and GL strings for each sample
  gl_strings <- map(samples, function(node){
    # Get sample ID
    sampleID <- node %>% xml_attr("id")
    # Get GL strings
    glstring <- node %>% xml_find_all( ".//d1:glstring") %>% xml_text()
    # Combine to a tibble
    tibble(sampleID, glstring)
  })

  # Create a table of the typing for each sample
  bind_rows(gl_strings) %>%
    mutate(locus = str_extract(glstring, "[^//*]+")) %>%
    # Some implementations of HML put the same locus in multiple nodes; this combines them with "+" to form a compliant GL string
    mutate(glstring = paste0(glstring, collapse = "+"), .by = c(sampleID, locus)) %>%
    distinct(sampleID, glstring, locus) %>%
    # Turn the data frame into one sample per row
    pivot_wider(names_from = locus, values_from = glstring) %>%
    # Combine to a single GL string per sample
    unite(GL_string, 2:last_col(), sep = "^", remove = TRUE, na.rm = TRUE)
}
