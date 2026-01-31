# 08_temp_pca.R
# Purpose:
# - PCA on temperature variables
# - Define ColderVariableTemp = -1 * PC1
#
# Input:
# - outputs/intermediate/phylo_objects.rds
# Output:
# - outputs/final/nestwatch_analysis_ready.rds (dat + pruned_tree)

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(dplyr); library(psych) })

obj <- readRDS("outputs/intermediate/phylo_objects.rds")
dat <- obj$dat_tree
pruned_tree <- obj$pruned_tree

temp_mat <- dat %>%
  select(temperature_min_C, temperature_max_C, temperature_mean_C, temperature_sd_C) %>%
  as.data.frame()

keep_rows <- complete.cases(temp_mat)
if (sum(keep_rows) < 5) stop("Too few complete rows for PCA.")

pca <- psych::principal(temp_mat[keep_rows,], nfactors=2, rotate="none")
print(pca)

dat$ColderVariableTemp <- NA_real_
dat$ColderVariableTemp[keep_rows] <- -1 * pca$scores[, "PC1"]

saveRDS(list(dat=dat, pruned_tree=pruned_tree),
        "outputs/final/nestwatch_analysis_ready.rds")
message("Wrote: outputs/final/nestwatch_analysis_ready.rds")
