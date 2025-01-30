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
#' read_HML("../tests/HML_1.hml")
#' read_HML("../tests/hml_2.hml")
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
  # Validate input
  if (!file.exists(HML_file)) {
    stop("The file does not exist:", HML_file)
  }

  # Load the HML file
  HML <- tryCatch({
    read_xml(HML_file)
  }, error = function(e){
    stop("Failed to read HML; check that file is in compliant HML format.")
  })

  # Filter for all the children in the HML file that represent a sample
  samples <- xml_find_all(HML, ".//d1:sample")

  # Get sample number and GL strings for each sample
  GL_strings <- map(samples, function(node){
    # Get sample ID
    sampleID <-  xml_attr(node, "id")
    # Get GL strings
    glstring <- xml_text(xml_find_all(node, ".//d1:glstring"))
    # Combine to a tibble
    tibble(sampleID, glstring)
  })

  # Combine to a single tibble.
  combined <- bind_rows(GL_strings)

  # Some implementations of HML put the same locus in multiple nodes; this combines them with "+" to form a compliant GL string
  reduced <- combined %>%
    mutate(locus = str_extract(glstring, "[^//*]+")) %>%
    mutate(glstring = paste0(glstring, collapse = "+"), .by = c(sampleID, locus)) %>%
    # Clean up values
    distinct(sampleID, glstring, locus) %>%
    filter(!is.na(sampleID) & !is.na(glstring)) %>%
    select(-locus)

  # Combine to a single GL string per sample
  summarise(reduced, GL_string = str_flatten(glstring, collapse = "^"), .by = sampleID)

}

globalVariables(c("glstring", "sampleID"))

