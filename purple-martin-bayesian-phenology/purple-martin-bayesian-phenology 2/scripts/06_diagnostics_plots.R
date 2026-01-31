# scripts/06_diagnostics_plots.R
# Plotting + derived quantities (R2, reaction norm plots, 3D surface) for the nest model

suppressPackageStartupMessages({
  library(tidyverse)
  library(coda)
  library(ggplot2)
  library(plot3D)
  library(reshape2)
})

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/models", recursive = TRUE, showWarnings = FALSE)

data <- read.csv("results/nest_data_clean.csv", stringsAsFactors = FALSE)

m <- readRDS("results/models/nest_mcmcglmm_chain1.rds")

# Trace plots
pdf("results/figures/nest_trace_fixed.pdf")
plot(m$Sol)
dev.off()

pdf("results/figures/nest_trace_random.pdf")
plot(m$VCV)
dev.off()

# --- Marginal/Conditional R2 (Nakagawa-style approximation) ---
# Here: var_fixed computed from posterior mean fitted values; random variance from VCV means
X_fixed <- model.matrix(~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within, data=data)

# Fitted values for each posterior draw (fixed effects only)
beta_draws <- as.matrix(m$Sol[, colnames(X_fixed), drop=FALSE])
fitted_draws <- beta_draws %*% t(X_fixed)   # draws x observations

# variance of fitted values for each draw; then posterior mean
var_fixed <- mean(apply(fitted_draws, 1, var))

# Posterior mean variance components
vcv_means <- colMeans(m$VCV)

# Identify residual
var_resid <- if ("units" %in% names(vcv_means)) vcv_means["units"] else NA_real_

# Random-effect variance total (exclude residual)
var_random_total <- sum(vcv_means[setdiff(names(vcv_means), "units")])

R2_marginal <- var_fixed / (var_fixed + var_random_total + var_resid)
R2_conditional <- (var_fixed + var_random_total) / (var_fixed + var_random_total + var_resid)

writeLines(
  c(paste0("Marginal R2: ", round(R2_marginal, 4)),
    paste0("Conditional R2: ", round(R2_conditional, 4))),
  con="results/tables/nest_R2.txt"
)

# --- 2D reaction norm plot (fixed-effect mean only) ---
posterior_means <- colMeans(m$Sol)

age_vals <- seq(min(data$age, na.rm=TRUE), max(data$age, na.rm=TRUE), length.out = 100)
KGCC_vals <- seq(min(data$KGCC, na.rm=TRUE), max(data$KGCC, na.rm=TRUE), length.out = 7)  # 7 lines for readability

# hold other covariates constant
lat0 <- mean(data$lat, na.rm=TRUE)
sex0 <- levels(factor(data$sex))[1]

new_data <- expand.grid(
  age = age_vals,
  KGCC = KGCC_vals,
  lat = lat0,
  sex = sex0,
  ID = levels(factor(data$ID))[1],
  Location = levels(factor(data$Location))[1]
)

# Recompute centered vars using population means for demonstration
# (For true within-individual predictions, center within an ID trajectory)
new_data$age_within <- new_data$age - mean(data$age, na.rm=TRUE)
new_data$age_mean <- mean(data$age, na.rm=TRUE)
new_data$KGCC_within <- new_data$KGCC - mean(data$KGCC, na.rm=TRUE)
new_data$KGCC_mean <- mean(data$KGCC, na.rm=TRUE)

Xnew <- model.matrix(~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within, data=new_data)
common <- intersect(colnames(Xnew), names(posterior_means))
new_data$predicted_doy <- as.vector(Xnew[, common, drop=FALSE] %*% posterior_means[common])

p1 <- ggplot(new_data, aes(x=age, y=predicted_doy, group=KGCC, color=factor(KGCC))) +
  geom_line(linewidth=1) +
  theme_bw(base_size = 14) +
  labs(x="Age", y="Predicted nest timing (DOY)", color="KGCC", title="Fixed-effect reaction norm: Age × KGCC")

ggsave("results/figures/reaction_norm_age_KGCC_lines.png", p1, width=8, height=5, dpi=300)

# --- 3D surface plot (fixed-effect mean only) ---
age_grid <- seq(min(data$age, na.rm=TRUE), max(data$age, na.rm=TRUE), length.out = 60)
kg_grid  <- seq(min(data$KGCC, na.rm=TRUE), max(data$KGCC, na.rm=TRUE), length.out = 60)

grid <- expand.grid(age=age_grid, KGCC=kg_grid)
grid$lat <- lat0
grid$sex <- sex0
grid$age_within <- grid$age - mean(data$age, na.rm=TRUE)
grid$age_mean <- mean(data$age, na.rm=TRUE)
grid$KGCC_within <- grid$KGCC - mean(data$KGCC, na.rm=TRUE)
grid$KGCC_mean <- mean(data$KGCC, na.rm=TRUE)

Xg <- model.matrix(~ age_within + age_mean + I(age_within^2) + KGCC_within + KGCC_mean + lat + sex + age_within:KGCC_within, data=grid)
grid$pred <- as.vector(Xg[, common, drop=FALSE] %*% posterior_means[common])

zmat <- acast(grid, age ~ KGCC, value.var="pred", fun.aggregate=mean)

png("results/figures/reaction_norm_surface.png", width=1200, height=900, res=150)
persp3D(x=age_grid, y=kg_grid, z=zmat, theta=40, phi=30, expand=0.6,
        xlab="Age", ylab="KGCC (Temperature)", zlab="Predicted DOY",
        contour=TRUE, ticktype="detailed", nticks=5, box=TRUE)
dev.off()

message("Diagnostics + plots saved to results/figures.")
