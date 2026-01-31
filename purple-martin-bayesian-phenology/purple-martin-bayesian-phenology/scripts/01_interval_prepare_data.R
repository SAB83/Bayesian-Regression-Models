# scripts/01_interval_prepare_data.R
# Prepare consecutive-year (interval) female dataset for modeling ΔEggDate
# Output: results/interval_data_clean.csv

suppressPackageStartupMessages({
  library(tidyverse)
  source("R/helpers.R")
})

# ==== USER: set your input path here ====
PATH_INTERVAL_DATA <- "/Users/sb69754/Library/CloudStorage/OneDrive-TheUniversityofTexasatAustin/egg_date/Kyle/dataf_t.csv"

# ==== output ====
OUT_PATH <- "results/interval_data_clean.csv"
dir.create("results", showWarnings = FALSE)

dataf <- read.csv(PATH_INTERVAL_DATA, stringsAsFactors = FALSE)

# Filter to females
dataf <- dataf %>% filter(sex == "F")

# Required columns for the interval analysis (adjust if your column names differ)
required <- c("EggDateInterval","age","KGCCInt","lat","ID","Location")
require_cols(dataf, required, "dataf")

# Coerce types
dataf <- dataf %>%
  mutate(
    ID = as_factor(ID),
    Location = as_factor(Location)
  )

# Keep complete cases for core predictors/response
data_clean <- dataf %>%
  filter(!is.na(age), !is.na(KGCCInt), !is.na(lat), !is.na(EggDateInterval))

# Make sure age is numeric for regression (if your age is categorical, keep it as factor)
# Here we treat age as numeric because your interval MCMCglmm uses 'age' as a slope.
if (is.factor(data_clean$age) || is.character(data_clean$age)) {
  suppressWarnings({
    data_clean$age <- as.numeric(as.character(data_clean$age))
  })
}

write.csv(data_clean, OUT_PATH, row.names = FALSE)
message("Saved: ", OUT_PATH, "  (n=", nrow(data_clean), ")")
