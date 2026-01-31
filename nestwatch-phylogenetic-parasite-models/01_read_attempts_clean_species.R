# 01_read_attempts_clean_species.R
# Purpose:
# - Read NestWatch attempts data
# - Turn blanks to NA
# - Remove ambiguous species names (sp., hybrids, slash names)
# - Coerce and sanity-check Year
#
# Input: cfg$paths$attempts_csv
# Output: outputs/intermediate/attempts_clean_step1.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr) })

attempts_path <- cfg$paths$attempts_csv
mydata <- readr::read_csv(attempts_path, show_col_types = FALSE) %>% as.data.frame()

# Turn blanks into NA
mydata[mydata == ""] <- NA

# Basic counts
if ("Species.Name" %in% names(mydata)) {
  message("After read: ", nrow(mydata), " rows; ",
          dplyr::n_distinct(mydata$Species.Name), " species")
} else stop("Missing Species.Name in attempts file.")

# Drop ambiguous species labels
n_before <- nrow(mydata)
mydata <- mydata %>%
  filter(!str_detect(Species.Name, "sp\\.")) %>%
  filter(!str_detect(Species.Name, " x ")) %>%
  filter(!str_detect(Species.Name, "/"))

message("After species filter: ", nrow(mydata), " rows (was ", n_before, "); ",
        dplyr::n_distinct(mydata$Species.Name), " species")

# Year sanity
require_cols(mydata, c("Year"), "attempts")
mydata$Year <- suppressWarnings(as.integer(mydata$Year))
mydata$Year[is.na(mydata$Year) | mydata$Year < YEAR_MIN | mydata$Year > YEAR_MAX] <- NA

out <- "outputs/intermediate/attempts_clean_step1.csv"
readr::write_csv(mydata, out)
message("Wrote: ", out)
