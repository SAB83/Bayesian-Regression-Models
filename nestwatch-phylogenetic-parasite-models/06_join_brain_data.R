# 06_join_brain_data.R
# Purpose:
# - Join BrainData (traits) by underscore species name
#
# Inputs:
# - outputs/intermediate/attempts_with_parasite.csv
# - cfg$paths$brain_rdata (loads BrainData)
# Output:
# - outputs/intermediate/attempts_with_brain.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

df <- readr::read_csv("outputs/intermediate/attempts_with_parasite.csv", show_col_types = FALSE)

load(cfg$paths$brain_rdata)  # must create BrainData object
if (!exists("BrainData")) stop("BrainData not found after loading brain_rdata.")

require_cols(df, c("ScientificName_us"), "attempts_with_parasite")
df <- df %>% mutate(Species = ScientificName_us)

brain_keep <- intersect(c("Species","Body.Mass","Brain.Mass","BrainResiNoPhy","PhyResMean","PhyResMode"), names(BrainData))

out_df <- df %>%
  left_join(BrainData %>% dplyr::select(all_of(brain_keep)), by="Species")

message("After brain join: ", nrow(out_df), " rows; ",
        dplyr::n_distinct(out_df$Species, na.rm=TRUE), " species")

out <- "outputs/intermediate/attempts_with_brain.csv"
readr::write_csv(out_df, out)
message("Wrote: ", out)
