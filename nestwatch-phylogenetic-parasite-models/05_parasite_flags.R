# 05_parasite_flags.R
# Purpose:
# - Create nest-level parasite presence flags (egg vs young) from checks data
# - Join flags back to attempts
#
# Inputs:
# - outputs/intermediate/attempts_with_temp.csv
# - cfg$paths$checks_csv
# Output:
# - outputs/intermediate/attempts_with_parasite.csv

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr) })

mydata   <- readr::read_csv("outputs/intermediate/attempts_with_temp.csv", show_col_types = FALSE)
parasite <- readr::read_csv(cfg$paths$checks_csv, show_col_types = FALSE)

# Standardize Attempt_ID
attempt_col_my  <- grep("^Attempt", names(mydata),   value = TRUE)[1]
attempt_col_par <- grep("^Attempt", names(parasite), value = TRUE)[1]
if (is.na(attempt_col_my) || is.na(attempt_col_par)) stop("Could not find Attempt* column in attempts or checks.")

mydata   <- mydata   %>% rename(Attempt_ID = all_of(attempt_col_my))  %>% mutate(Attempt_ID = as.character(Attempt_ID))
parasite <- parasite %>% rename(Attempt_ID = all_of(attempt_col_par)) %>% mutate(Attempt_ID = as.character(Attempt_ID))

parasite_cols_canonical <- c(
  "Brood.Parasite.Eggs.Count",
  "Brood.Parasite.Eggs.Present.Uncounted",
  "Brood.Parasite.Live.Young.Count",
  "Brood.Parasite.Live.Young.Present.Uncounted",
  "Brood.Parasite.Dead.Young.Count",
  "Brood.Parasite.Dead.Young.Present.Uncounted"
)

# Robust column matching: normalize punctuation/case
norm <- function(x) gsub("[^A-Za-z0-9]+", "", tolower(x))
name_map <- setNames(names(parasite), norm(names(parasite)))
need_norm <- norm(parasite_cols_canonical)

missing_norm <- setdiff(need_norm, names(name_map))
if (length(missing_norm) > 0) stop("Missing parasite columns in checks file (normalized): ", paste(missing_norm, collapse=", "))

matched_original <- unname(name_map[need_norm])
names(parasite)[match(matched_original, names(parasite))] <- parasite_cols_canonical

# Ensure numeric
parasite[parasite_cols_canonical] <- lapply(parasite[parasite_cols_canonical], function(x){
  x <- str_squish(as.character(x))
  x[x %in% c("", "NA", "NaN")] <- NA
  suppressWarnings(as.numeric(x))
})

parasite_by_attempt <- parasite %>%
  mutate(
    egg_visit_pos = (
      (!is.na(Brood.Parasite.Eggs.Count) & Brood.Parasite.Eggs.Count > 0) |
      (!is.na(Brood.Parasite.Eggs.Present.Uncounted) & Brood.Parasite.Eggs.Present.Uncounted == 1)
    ),
    young_visit_pos = (
      (!is.na(Brood.Parasite.Live.Young.Count) & Brood.Parasite.Live.Young.Count > 0) |
      (!is.na(Brood.Parasite.Live.Young.Present.Uncounted) & Brood.Parasite.Live.Young.Present.Uncounted == 1) |
      (!is.na(Brood.Parasite.Dead.Young.Count) & Brood.Parasite.Dead.Young.Count > 0) |
      (!is.na(Brood.Parasite.Dead.Young.Present.Uncounted) & Brood.Parasite.Dead.Young.Present.Uncounted == 1)
    )
  ) %>%
  group_by(Attempt_ID) %>%
  summarise(
    egg_par_positive   = as.integer(any(egg_visit_pos,   na.rm=TRUE)),
    young_par_positive = as.integer(any(young_visit_pos, na.rm=TRUE)),
    .groups="drop"
  )

out_df <- mydata %>%
  left_join(parasite_by_attempt, by="Attempt_ID") %>%
  mutate(
    egg_par_positive   = ifelse(is.na(egg_par_positive),   0L, egg_par_positive),
    young_par_positive = ifelse(is.na(young_par_positive), 0L, young_par_positive)
  )

message("Cross-tab egg vs young:")
print(with(out_df, table(egg_par_positive, young_par_positive, useNA="ifany")))

out <- "outputs/intermediate/attempts_with_parasite.csv"
readr::write_csv(out_df, out)
message("Wrote: ", out)
