# 04_join_temperature.R
# Purpose:
# - Join temperature summaries to attempts by Attempt ID
#
# Inputs:
# - outputs/intermediate/attempts_with_scientific.csv
# - cfg$paths$temp_csv
# Output:
# - outputs/intermediate/attempts_with_temp.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

mydata <- readr::read_csv("outputs/intermediate/attempts_with_scientific.csv", show_col_types = FALSE)
temp   <- readr::read_csv(cfg$paths$temp_csv, show_col_types = FALSE)

# Standardize Attempt ID columns
attempt_col_my <- grep("^Attempt", names(mydata), value = TRUE)[1]
attempt_col_tp <- grep("^Attempt", names(temp),   value = TRUE)[1]
if (is.na(attempt_col_my) || is.na(attempt_col_tp)) stop("Could not find Attempt* column in attempts or temp.")

mydata <- mydata %>% rename(Attempt_ID = all_of(attempt_col_my)) %>% mutate(Attempt_ID = as.character(Attempt_ID))
temp   <- temp   %>% rename(Attempt_ID = all_of(attempt_col_tp)) %>% mutate(Attempt_ID = as.character(Attempt_ID))

temp_sel <- temp %>% select(
  Attempt_ID,
  temperature_max_C, temperature_mean_C, temperature_min_C,
  temperature_range_C, temperature_sd_C, temperature_variance_C
)

out_df <- mydata %>% left_join(temp_sel, by="Attempt_ID")

out <- "outputs/intermediate/attempts_with_temp.csv"
readr::write_csv(out_df, out)
message("Wrote: ", out)
message("Missing temperature_mean_C: ", sum(is.na(out_df$temperature_mean_C)))
