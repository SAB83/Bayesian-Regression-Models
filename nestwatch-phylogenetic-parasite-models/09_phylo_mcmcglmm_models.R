# 09_phylo_mcmcglmm_models.R
# Purpose:
# - Prepare final dataset for phylogenetic models
# - Align phylogeny tips with Species factor levels
# - Build Ainv and fit 3 MCMCglmm models:
#   1) egg_par_positive (categorical)
#   2) young_par_positive (categorical)
#   3) Young.Fledged (poisson)
#
# Input:
# - outputs/final/nestwatch_analysis_ready.rds
# Outputs:
# - outputs/models/*.rds
# - outputs/tables/summary_*.txt

source("scripts/00_setup.R")
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(MCMCglmm)
  library(ape)
})

obj <- readRDS("outputs/final/nestwatch_analysis_ready.rds")
dat <- obj$dat
pruned_tree <- obj$pruned_tree

# Data prep for models
dat_mod <- dat %>%
  mutate(
    Young.Fledged = suppressWarnings(as.numeric(Young.Fledged)),
    Clutch.Size   = suppressWarnings(as.numeric(Clutch.Size)),
    egg_par_positive   = factor(egg_par_positive, levels=c(0,1)),
    young_par_positive = factor(young_par_positive, levels=c(0,1)),
    log_body = log(Body.Mass)
  ) %>%
  filter(!is.na(Clutch.Size), Clutch.Size > 0) %>%
  drop_na(
    log_body, PhyResMean, ColderVariableTemp, Clutch.Size,
    egg_par_positive, young_par_positive, Species_tree
  )

# Use exact tree tips
dat_mod$Species <- factor(dat_mod$Species_tree)

phy_use <- drop.tip(pruned_tree, setdiff(pruned_tree$tip.label, unique(dat_mod$Species)))
dat_phy <- dat_mod %>% filter(Species %in% phy_use$tip.label)
dat_phy$Species <- factor(dat_phy$Species, levels = phy_use$tip.label)

phy_use$node.label <- paste0("Node_", seq_len(phy_use$Nnode))
Ainv <- inverseA(phy_use, nodes="TIPS", scale=TRUE)$Ainv

# Priors
prior_cat_phy <- list(
  G = list(G1 = list(V = 1, nu = 0.002)),
  R = list(V = 1, fix = 1)
)

prior_pois_phy <- list(
  G = list(G1 = list(V = 1, nu = 0.002)),
  R = list(V = 1, fix = 1)
)

set.seed(1)

# MODEL 1: egg parasite presence
m_egg <- MCMCglmm(
  egg_par_positive ~ log_body + ColderVariableTemp + Clutch.Size + PhyResMean + PhyResMean:ColderVariableTemp,
  random   = ~ Species,
  family   = "categorical",
  data     = dat_phy,
  ginverse = list(Species = Ainv),
  prior    = prior_cat_phy,
  nitt     = 130000,
  burnin   = 30000,
  thin     = 100,
  verbose  = FALSE
)

# MODEL 2: young parasite presence
m_young <- MCMCglmm(
  young_par_positive ~ log_body + ColderVariableTemp + Clutch.Size + PhyResMean +
    egg_par_positive + PhyResMean:ColderVariableTemp + PhyResMean:egg_par_positive,
  random   = ~ Species,
  family   = "categorical",
  data     = dat_phy,
  ginverse = list(Species = Ainv),
  prior    = prior_cat_phy,
  nitt     = 130000,
  burnin   = 30000,
  thin     = 100,
  verbose  = FALSE
)

# MODEL 3: fledging count
m_fledge <- MCMCglmm(
  Young.Fledged ~ log_body + ColderVariableTemp + Clutch.Size + PhyResMean +
    egg_par_positive + young_par_positive +
    PhyResMean:ColderVariableTemp + PhyResMean:egg_par_positive + PhyResMean:young_par_positive,
  random   = ~ Species,
  family   = "poisson",
  data     = dat_phy,
  ginverse = list(Species = Ainv),
  prior    = prior_pois_phy,
  nitt     = 130000,
  burnin   = 30000,
  thin     = 100,
  verbose  = FALSE
)

saveRDS(m_egg,    "outputs/models/mcmcglmm_egg_parasite.rds")
saveRDS(m_young,  "outputs/models/mcmcglmm_young_parasite.rds")
saveRDS(m_fledge, "outputs/models/mcmcglmm_fledge_poisson.rds")

capture.output(summary(m_egg),    file="outputs/tables/summary_m_egg.txt")
capture.output(summary(m_young),  file="outputs/tables/summary_m_young.txt")
capture.output(summary(m_fledge), file="outputs/tables/summary_m_fledge.txt")

message("Models fitted + saved in outputs/models and outputs/tables")
