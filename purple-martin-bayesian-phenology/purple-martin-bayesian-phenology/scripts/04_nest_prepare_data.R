# scripts/04_nest_prepare_data.R
# Prepare nest-timing dataset for reaction norm + within/between centering models
# Output: results/nest_data_clean.csv with centered variables

suppressPackageStartupMessages({
  library(tidyverse)
  source("R/helpers.R")
})

# ==== USER: set your input path here ====
PATH_NEST_DATA <- "/Users/sb69754/Library/CloudStorage/OneDrive-TheUniversityofTexasatAustin/egg_date/Kyle/tnest.csv"

OUT_PATH <- "results/nest_data_clean.csv"
dir.create("results", showWarnings = FALSE)

data <- read.csv(PATH_NEST_DATA, stringsAsFactors = FALSE)

required <- c("doy","age","KGCC","lat","sex","ID","Location")
require_cols(data, required, "nest data")

data <- data %>%
  mutate(
    sex = as_factor(sex),
    ID = as_factor(ID),
    Location = as_factor(Location)
  ) %>%
  filter(!is.na(age), !is.na(doy), !is.na(KGCC), !is.na(lat))

# age must be numeric for quadratic + interaction; convert safely
if (is.factor(data$age) || is.character(data$age)) {
  suppressWarnings({
    data$age <- as.numeric(as.character(data$age))
  })
}

# Within–between centering for age and KGCC by individual
wb_age  <- wb_center(data$age,  data$ID)
wb_temp <- wb_center(data$KGCC, data$ID)

data <- data %>%
  mutate(
    age_within = wb_age$within,
    age_mean   = wb_age$mean,
    KGCC_within = wb_temp$within,
    KGCC_mean   = wb_temp$mean
  )

write.csv(data, OUT_PATH, row.names = FALSE)
message("Saved: ", OUT_PATH, "  (n=", nrow(data), ")")
