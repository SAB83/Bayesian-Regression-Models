# 10_diagnostics_export.R
# Purpose:
# - Export Geweke diagnostics for fixed effects (Sol) and variance components (VCV)

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(coda) })

m_egg    <- readRDS("outputs/models/mcmcglmm_egg_parasite.rds")
m_young  <- readRDS("outputs/models/mcmcglmm_young_parasite.rds")
m_fledge <- readRDS("outputs/models/mcmcglmm_fledge_poisson.rds")

diag_one <- function(m, name) {
  sol <- as.mcmc(m$Sol)
  vcv <- as.mcmc(m$VCV)

  g_sol <- geweke.diag(sol)
  g_vcv <- geweke.diag(vcv)

  out <- c(
    paste0("==== ", name, " ===="),
    "Fixed effects (Sol) Geweke z:",
    capture.output(print(g_sol$z)),
    "",
    "Variance components (VCV) Geweke z:",
    capture.output(print(g_vcv$z))
  )

  writeLines(out, con=paste0("outputs/tables/diagnostics_", name, ".txt"))
}

diag_one(m_egg, "m_egg")
diag_one(m_young, "m_young")
diag_one(m_fledge, "m_fledge")

message("Diagnostics exported to outputs/tables/")
