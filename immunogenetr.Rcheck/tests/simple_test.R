library(tidyverse)

test <- read_csv("tests/test3.csv")

test %>% HLA_column_repair()
