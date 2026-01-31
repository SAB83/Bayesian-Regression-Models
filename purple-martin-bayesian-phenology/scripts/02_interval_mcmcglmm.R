# scripts/02_interval_mcmcglmm.R
# Bayesian mixed model (MCMCglmm) for interannual change in egg-laying date (ΔEggDate)
# Model: EggDateInterval ~ age + KGCCInt + lat + (1|ID) + (1|Location)
# Output: results/models/interval_mcmcglmm_chain*.rds + tables/summary

suppressPackageStartupMessages({
  library(tidyverse)
  library(MCMCglmm)
  library(coda)
  source("R/helpers.R")
})

DATA_PATH <- "results/interval_data_clean.csv"
dir.create("results/models", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

data <- read.csv(DATA_PATH, stringsAsFactors = FALSE)

# Ensure types
data <- data %>%
  mutate(
    ID = as_factor(ID),
    Location = as_factor(Location)
  )

# Fixed effects: (Intercept) + age + KGCCInt + lat  => 4 parameters
nB <- 4

# Weakly-informative priors (Hadfield-style)
prior <- list(
  B = list(mu = rep(0, nB), V = diag(1e6, nB)),
  R = list(V = 1, nu = 0.002),
  G = list(
    G1 = list(V = 1, nu = 0.002),  # Location
    G2 = list(V = 1, nu = 0.002)   # ID
  )
)

fit_once <- function() {
  MCMCglmm(
    EggDateInterval ~ age + KGCCInt + lat,
    random = ~ Location + ID,
    family = "gaussian",
    prior = prior,
    data = data,
    nitt = 200000,
    burnin = 10000,
    thin = 100,
    verbose = FALSE
  )
}

# Run 3 chains for diagnostics
fits <- run_mcmcglmm_chains(fit_once, seeds=c(101, 202, 303))

# Save chains
for (i in seq_along(fits)) {
  saveRDS(fits[[i]], file = sprintf("results/models/interval_mcmcglmm_chain%i.rds", i))
}

# Convergence diagnostics (Gelman-Rubin)
gr <- gelman_mcmcglmm(fits)
saveRDS(gr, "results/tables/interval_mcmcglmm_gelman.rds")

# Use chain 1 as the "main" model for summaries/plots
mc <- fits[[1]]

# Summaries
sum_mc <- summary(mc)
capture.output(sum_mc, file="results/tables/interval_mcmcglmm_summary.txt")

# Autocorrelation (fixed + random)
auto_fixed  <- autocorr(as.mcmc(mc$Sol))
auto_random <- autocorr(as.mcmc(mc$VCV))
saveRDS(auto_fixed,  "results/tables/interval_autocorr_fixed.rds")
saveRDS(auto_random, "results/tables/interval_autocorr_random.rds")

# Geweke diagnostics
gz_fixed <- geweke.diag(as.mcmc(mc$Sol))
gz_rand  <- geweke.diag(as.mcmc(mc$VCV))
saveRDS(gz_fixed, "results/tables/interval_geweke_fixed.rds")
saveRDS(gz_rand,  "results/tables/interval_geweke_random.rds")

# DIC (single chain)
dic <- mc$DIC
writeLines(paste("DIC:", dic), con="results/tables/interval_mcmcglmm_DIC.txt")

message("Done. Main outputs in results/models and results/tables.")
