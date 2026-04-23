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
#' HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")
#' HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")
#'
#' read_HML(HML_1)
#' read_HML(HML_2)
#'
#' @export
#'
#' @importFrom cli cli_abort
#' @importFrom xml2 read_xml
#' @importFrom dplyr %>%
#' @importFrom xml2 xml_find_all
#' @importFrom xml2 xml_ns
#' @importFrom purrr map
#' @importFrom xml2 xml_attr
#' @importFrom xml2 xml_find_all
#' @importFrom xml2 xml_text
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @importFrom dplyr mutate
#' @importFrom stringr str_extract
#' @importFrom dplyr distinct
#' @importFrom dplyr filter
#' @importFrom dplyr summarise
#' @importFrom stringr str_flatten
#' @importFrom tidyr pivot_wider
#' @importFrom tidyr unite

read_HML <- function(HML_file) {
  # Validate input
  check_gl_string(HML_file, "HML_file")
  if (!file.exists(HML_file)) {
    cli_abort("The file {.file {HML_file}} does not exist.")
  }

  # Load the HML file
  HML <- tryCatch(
    {
      read_xml(HML_file)
    },
    error = function(e) {
      cli_abort("Failed to read HML file {.file {HML_file}}. Check that file is in compliant HML format.")
    }
  )

  # Discover the XML namespace dynamically instead of hardcoding "d1:".
  # xml2 auto-registers default (unprefixed) namespaces as "d1", "d2", etc.,
  # but this can vary depending on the file structure.
  ns <- xml_ns(HML)

  # Build XPath queries using the discovered namespace prefix.
  # If a namespace is present, use its prefix; otherwise use unqualified names.
  if (length(ns) > 0) {
    # Use the first registered namespace prefix (typically "d1" for default namespace).
    ns_prefix <- names(ns)[1]
    sample_xpath <- paste0(".//", ns_prefix, ":sample")
    glstring_xpath <- paste0(".//", ns_prefix, ":glstring")
  } else {
    # No namespace declared; use unqualified element names.
    sample_xpath <- ".//sample"
    glstring_xpath <- ".//glstring"
  }

  # Filter for all the children in the HML file that represent a sample.
  samples <- xml_find_all(HML, sample_xpath, ns)

  # Get sample number and GL strings for each sample.
  GL_strings <- map(samples, function(node) {
    # Get sample ID.
    sampleID <- xml_attr(node, "id")
    # Get GL strings.
    glstring <- xml_text(xml_find_all(node, glstring_xpath, ns))
    # Combine to a tibble.
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
