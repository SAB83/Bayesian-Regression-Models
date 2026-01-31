# R/helpers.R
# Shared helper utilities for this repository

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(coda)
})

#' Ensure required columns exist
require_cols <- function(df, cols, df_name="data") {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    stop(sprintf("Missing required columns in %s: %s", df_name, paste(missing, collapse=", ")))
  }
  invisible(TRUE)
}

#' Convert to factor safely (keeps existing levels unless specified)
as_factor <- function(x) {
  if (is.factor(x)) return(x)
  factor(x)
}

#' Simple function for within–between centering
#' returns a list: within, between (mean)
wb_center <- function(x, id) {
  m <- ave(x, id, FUN=function(z) mean(z, na.rm=TRUE))
  list(within = x - m, mean = m)
}

#' Run multiple MCMCglmm chains for Gelman-Rubin diagnostic
#' Returns a list of fitted models
run_mcmcglmm_chains <- function(fit_fun, seeds=c(1,2,3)) {
  fits <- vector("list", length(seeds))
  for (i in seq_along(seeds)) {
    set.seed(seeds[i])
    fits[[i]] <- fit_fun()
  }
  fits
}

#' Gelman-Rubin diagnostic for MCMCglmm fixed effects + variance components
gelman_mcmcglmm <- function(fits) {
  # Fixed effects
  sol_list <- mcmc.list(lapply(fits, function(f) as.mcmc(f$Sol)))
  vcv_list <- mcmc.list(lapply(fits, function(f) as.mcmc(f$VCV)))
  list(
    fixed = gelman.diag(sol_list, autoburnin=FALSE),
    random = gelman.diag(vcv_list, autoburnin=FALSE)
  )
}

#' Posterior predictive lines for 2D plots (fixed-effect mean only)
predict_fixed_only <- function(post_sol, newX) {
  # post_sol: matrix draws x params (columns)
  # newX: model.matrix for new data
  beta <- as.matrix(post_sol)
  if (ncol(newX) != ncol(beta)) stop("newX columns must match posterior Sol columns.")
  as.vector(newX %*% colMeans(beta))
}
