# scripts/05_nest_mcmcglmm_reaction_norms.R
# Reaction norm model for nest timing (doy) with within-between centered age & temperature
# Model (fixed): doy ~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within
# Random: ~ us(KGCC_within + age_within):ID + Location
#
# Output: results/models/nest_mcmcglmm_chain*.rds + tables

suppressPackageStartupMessages({
  library(tidyverse)
  library(MCMCglmm)
  library(coda)
  source("R/helpers.R")
})

DATA_PATH <- "results/nest_data_clean.csv"
dir.create("results/models", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

data <- read.csv(DATA_PATH, stringsAsFactors = FALSE) %>%
  mutate(
    sex = as_factor(sex),
    ID = as_factor(ID),
    Location = as_factor(Location)
  )

# Fixed effects count:
# (Intercept), age_within, age_mean, I(age_within^2), KGCC_within, KGCC_mean, lat, sex (1 coef if 2 levels), age_within:KGCC_within
# Because sex is a factor, its number of coefficients depends on levels.
# We'll build the model matrix to set B dimension correctly.
X <- model.matrix(~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within, data=data)
nB <- ncol(X)

# Random slopes by ID: 2-dimensional (KGCC_within + age_within) => 2x2 covariance
prior <- list(
  B = list(mu = rep(0, nB), V = diag(1e8, nB)),
  R = list(V = 1, nu = 0.002),
  G = list(
    G1 = list(V = diag(2), nu = 0.02),  # us(KGCC_within + age_within):ID
    G2 = list(V = 1, nu = 0.02)         # Location intercept
  )
)

fit_once <- function() {
  MCMCglmm(
    doy ~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within,
    random = ~ us(KGCC_within + age_within):ID + Location,
    family = "gaussian",
    data = data,
    prior = prior,
    nitt = 400000,
    burnin = 40000,
    thin = 300,
    verbose = FALSE
  )
}

# 3 chains
fits <- run_mcmcglmm_chains(fit_once, seeds=c(111,222,333))

for (i in seq_along(fits)) {
  saveRDS(fits[[i]], file = sprintf("results/models/nest_mcmcglmm_chain%i.rds", i))
}

gr <- gelman_mcmcglmm(fits)
saveRDS(gr, "results/tables/nest_mcmcglmm_gelman.rds")

m <- fits[[1]]
capture.output(summary(m), file="results/tables/nest_mcmcglmm_summary.txt")
writeLines(paste("DIC:", m$DIC), con="results/tables/nest_mcmcglmm_DIC.txt")

# Diagnostics
saveRDS(autocorr(as.mcmc(m$Sol)), "results/tables/nest_autocorr_fixed.rds")
saveRDS(autocorr(as.mcmc(m$VCV)), "results/tables/nest_autocorr_random.rds")
saveRDS(geweke.diag(as.mcmc(m$Sol)), "results/tables/nest_geweke_fixed.rds")
saveRDS(geweke.diag(as.mcmc(m$VCV)), "results/tables/nest_geweke_random.rds")

message("Nest reaction-norm model done.")
