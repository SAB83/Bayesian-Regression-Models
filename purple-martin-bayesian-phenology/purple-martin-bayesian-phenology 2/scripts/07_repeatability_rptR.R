# scripts/07_repeatability_rptR.R
# Repeatability of breeding timing using rptR
# Output: results/tables/repeatability_*.txt

suppressPackageStartupMessages({
  library(tidyverse)
  library(rptR)
  source("R/helpers.R")
})

DATA_PATH <- "results/nest_data_clean.csv"
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

data <- read.csv(DATA_PATH, stringsAsFactors = FALSE) %>%
  mutate(
    sex = as_factor(sex),
    ID = as_factor(ID)
  )

# Female-only
data_female <- data %>% filter(sex == "F")
# Male-only
data_male <- data %>% filter(sex == "M")

# Adjusted repeatability (controls for covariates)
r_f_adj <- rpt(doy ~ age + lat + KGCC + (1|ID),
               gr = "ID",
               data = data_female,
               datatype = "Gaussian",
               adjusted = TRUE,
               nboot = 1000, npermut = 0)

r_m_adj <- rpt(doy ~ age + lat + KGCC + (1|ID),
               gr = "ID",
               data = data_male,
               datatype = "Gaussian",
               adjusted = TRUE,
               nboot = 1000, npermut = 0)

# Unadjusted repeatability (intercept-only)
r_f_unadj <- rpt(doy ~ (1|ID),
                 gr = "ID",
                 data = data_female,
                 datatype = "Gaussian",
                 adjusted = FALSE,
                 nboot = 1000, npermut = 0)

r_m_unadj <- rpt(doy ~ (1|ID),
                 gr = "ID",
                 data = data_male,
                 datatype = "Gaussian",
                 adjusted = FALSE,
                 nboot = 1000, npermut = 0)

capture.output(r_f_adj,   file="results/tables/repeatability_female_adjusted.txt")
capture.output(r_m_adj,   file="results/tables/repeatability_male_adjusted.txt")
capture.output(r_f_unadj, file="results/tables/repeatability_female_unadjusted.txt")
capture.output(r_m_unadj, file="results/tables/repeatability_male_unadjusted.txt")

message("Repeatability outputs saved to results/tables/.")
