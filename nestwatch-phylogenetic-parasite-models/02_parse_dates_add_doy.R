# 02_parse_dates_add_doy.R
# Purpose:
# - Standardize date strings to YYYY-MM-DD
# - Create DOY columns for any present nesting date fields
#
# Input: outputs/intermediate/attempts_clean_step1.csv
# Output: outputs/intermediate/attempts_with_doy.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

infile <- "outputs/intermediate/attempts_clean_step1.csv"
mydata <- readr::read_csv(infile, show_col_types = FALSE) %>% as.data.frame()

possible_date_names <- c(
  "First.Lay.Date","Hatch.Date","Fledge.Date",
  "First Lay Date","Hatch Date","Fledge Date"
)
present_dates <- intersect(possible_date_names, names(mydata))

for (dc in present_dates) {
  res <- build_date_and_doy(mydata[[dc]], mydata$Year)
  mydata[[dc]] <- res$date
  mydata[[paste0(dc, ".DOY")]] <- res$doy
}

out <- "outputs/intermediate/attempts_with_doy.csv"
readr::write_csv(mydata, out)
message("Wrote: ", out, " with DOY columns for: ", paste(present_dates, collapse=", "))
