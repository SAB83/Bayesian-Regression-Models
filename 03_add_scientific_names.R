# 03_add_scientific_names.R
# Purpose:
# - Join eBird taxonomy to add scientific names
# - Create both space and underscore formats for downstream joins
#
# Inputs:
# - outputs/intermediate/attempts_with_doy.csv
# - cfg$paths$ebird_tax (must include PRIMARY_COM_NAME and SCI_NAME)
# Output:
# - outputs/intermediate/attempts_with_scientific.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr) })

mydata <- readr::read_csv("outputs/intermediate/attempts_with_doy.csv", show_col_types = FALSE)
spnames <- readr::read_csv(cfg$paths$ebird_tax, show_col_types = FALSE)

require_cols(mydata, c("Species.Name"), "attempts")
require_cols(spnames, c("PRIMARY_COM_NAME","SCI_NAME"), "ebird taxonomy")

mydata2 <- mydata %>%
  left_join(spnames %>% select(PRIMARY_COM_NAME, SCI_NAME),
            by = c("Species.Name" = "PRIMARY_COM_NAME")) %>%
  rename(ScientificName_sp = SCI_NAME) %>%
  mutate(ScientificName_us = ifelse(is.na(ScientificName_sp), NA_character_,
                                   str_replace_all(ScientificName_sp, " ", "_")))

message("After scientific names: ", nrow(mydata2), " rows; ",
        dplyr::n_distinct(mydata2$ScientificName_us, na.rm=TRUE), " species (ScientificName_us)")

out <- "outputs/intermediate/attempts_with_scientific.csv"
readr::write_csv(mydata2, out)
message("Wrote: ", out)
