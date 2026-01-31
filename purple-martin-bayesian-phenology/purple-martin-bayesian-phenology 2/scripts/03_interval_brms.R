# scripts/03_interval_brms.R
# brms version of interval model (ΔEggDate) for comparison / robustness
# Output: results/models/interval_brms.rds + tables

suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(loo)
  source("R/helpers.R")
})

DATA_PATH <- "results/interval_data_clean.csv"
dir.create("results/models", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

data <- read.csv(DATA_PATH, stringsAsFactors = FALSE) %>%
  mutate(
    ID = as_factor(ID),
    Location = as_factor(Location)
  )

# Priors
priors <- c(
  set_prior("normal(0, 10)", class = "b"),
  set_prior("normal(0, 10)", class = "Intercept"),
  set_prior("student_t(3, 0, 10)", class = "sd"),
  set_prior("student_t(3, 0, 10)", class = "sigma")
)

m_interval <- brm(
  EggDateInterval ~ age + KGCCInt + lat + (1|Location) + (1|ID),
  data = data,
  family = gaussian(),
  prior = priors,
  chains = 4,
  iter = 8000,
  warmup = 4000,
  cores = min(4, parallel::detectCores()),
  control = list(adapt_delta = 0.95, max_treedepth = 15),
  seed = 123
)

saveRDS(m_interval, "results/models/interval_brms.rds")
capture.output(summary(m_interval), file="results/tables/interval_brms_summary.txt")

# LOO
loo_interval <- loo(m_interval)
saveRDS(loo_interval, "results/tables/interval_brms_loo.rds")

# PPC + trace plots saved as files (optional interactive)
pdf("results/figures/interval_brms_trace.pdf")
plot(m_interval)
dev.off()

pdf("results/figures/interval_brms_ppc.pdf")
pp_check(m_interval)
dev.off()

message("Saved brms model + LOO + plots.")
