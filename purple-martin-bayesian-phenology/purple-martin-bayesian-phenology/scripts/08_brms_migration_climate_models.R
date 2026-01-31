# scripts/08_brms_migration_climate_models.R
# General brms workflow for climate effects on migration timing / phenology + LOO comparison
# This is the cleaned, runnable version of your "Bayesian-Regression-Models" block.

suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(loo)
  source("R/helpers.R")
})

dir.create("results/models", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

# ==== USER: set your dataset path + required column names ====
# Example: data <- read.csv("data/your_dataset.csv")
# You MUST ensure these columns exist (change names as needed):
# saDOY, doy, age, lat, lon, long, sex, KGCC, loc, sdDOY, artemps1, deptemps1, depsnows1, tema, snowa, s1du, km

# Placeholder (STOP if not replaced)
STOP_IF_NOT_SET <- TRUE
if (STOP_IF_NOT_SET) stop("Edit scripts/08_brms_migration_climate_models.R: load your dataset first and set STOP_IF_NOT_SET <- FALSE")

# data <- read.csv("PATH_TO_YOUR_DATA.csv")
# STOP_IF_NOT_SET <- FALSE

# ---- Priors ----
priors_basic <- c(
  set_prior("normal(0, 10)", class = "b"),
  set_prior("normal(0, 10)", class = "Intercept")
)

priors_with_random <- c(
  set_prior("normal(0, 10)", class = "b"),
  set_prior("normal(0, 10)", class = "Intercept"),
  set_prior("normal(0, 5)", class = "sd"),
  set_prior("student_t(3, 0, 10)", class = "sigma")
)

# ---- Model A: climate change impacts on migration timing (example) ----
# formula: saDOY ~ lat + lon + sdDOY + artemps1 + deptemps1 + depsnows1 + tema + snowa + s1du + km
model_saDOY <- brm(
  saDOY ~ lat + lon + sdDOY + artemps1 + deptemps1 + depsnows1 + tema + snowa + s1du + km,
  data = data,
  family = gaussian(),
  prior = priors_basic,
  warmup = 4000,
  iter = 8000,
  chains = 4,
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  seed = 123
)
saveRDS(model_saDOY, "results/models/brms_saDOY_climate.rds")
capture.output(summary(model_saDOY), file="results/tables/brms_saDOY_climate_summary.txt")

# ---- Model set: doy ~ ... + (1|loc) comparisons ----
model0 <- brm(
  doy ~ age + lat + long + sex + KGCC + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  seed = 123
)

model1 <- brm(
  doy ~ age + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.99, max_treedepth = 15),
  seed = 123
)

model2 <- brm(
  doy ~ age + KGCC + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  seed = 123
)

model3 <- brm(
  doy ~ age + lat + KGCC + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.995, max_treedepth = 20),
  seed = 123
)

model4 <- brm(
  doy ~ age + lat + KGCC + sex + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.995, max_treedepth = 25),
  seed = 123
)

model5 <- brm(
  doy ~ age + lat + KGCC + long + (1|loc),
  data = data,
  family = gaussian(),
  prior = priors_with_random,
  warmup = 4000, iter = 8000, chains = 4,
  control = list(adapt_delta = 0.995, max_treedepth = 25),
  seed = 123
)

saveRDS(model0, "results/models/brms_doy_model0.rds")
saveRDS(model1, "results/models/brms_doy_model1.rds")
saveRDS(model2, "results/models/brms_doy_model2.rds")
saveRDS(model3, "results/models/brms_doy_model3.rds")
saveRDS(model4, "results/models/brms_doy_model4.rds")
saveRDS(model5, "results/models/brms_doy_model5.rds")

# ---- LOO comparison ----
loo0 <- loo(model0)
loo1 <- loo(model1)
loo2 <- loo(model2)
loo3 <- loo(model3)
loo4 <- loo(model4)
loo5 <- loo(model5)

loo_comp <- loo_compare(loo0, loo1, loo2, loo3, loo4, loo5)
saveRDS(list(loo0=loo0, loo1=loo1, loo2=loo2, loo3=loo3, loo4=loo4, loo5=loo5, compare=loo_comp),
        "results/tables/brms_loo_comparison.rds")

capture.output(loo_comp, file="results/tables/brms_loo_comparison.txt")

# Bayes factors (optional; expensive; requires bridgesampling)
# bf12 <- bayes_factor(model1, model2)
# bf13 <- bayes_factor(model1, model3)

# Basic checks
pdf("results/figures/brms_ppc_model2.pdf")
pp_check(model2)
dev.off()

capture.output(summary(model2), file="results/tables/brms_model2_summary.txt")

message("brms migration/climate workflow complete.")
