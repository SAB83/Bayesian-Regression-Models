# Purple Martin phenology: Bayesian mixed models, plasticity, and repeatability

This repository contains **reproducible R scripts** for the analyses described in the accompanying manuscript
(`Phenotypic plasticity in the timing of egg laying in response to temperature and age in individual long-distance migratory songbirds`).

Main goals:
1) Model **interannual change in egg-laying date** (ΔEggDate; consecutive-year pairs) as a function of
   interannual temperature change (ΔKGCC spring-window mean temperature), age category, and latitude.
2) Model **nest timing (DOY)** in known-age birds (1–10y) using **within–between centering** to separate
   within-individual plasticity from among-individual patterns, including age-dependent reaction norms.
3) Estimate **repeatability** (R) of breeding timing with `rptR`.
4) Provide an additional **brms workflow** for climate/phenology regression models + model comparison via `loo`.

> NOTE: The scripts are designed so you can run them end-to-end **without editing any code except the file paths**
> and (optionally) the KGCC-window temperature inputs if you compute them elsewhere.

---

## Repository structure

```
purple-martin-bayesian-phenology/
  README.md
  renv/                     # optional (not included)
  R/
    helpers.R               # shared helper functions
  scripts/
    01_interval_prepare_data.R
    02_interval_mcmcglmm.R
    03_interval_brms.R
    04_nest_prepare_data.R
    05_nest_mcmcglmm_reaction_norms.R
    06_diagnostics_plots.R
    07_repeatability_rptR.R
    08_brms_migration_climate_models.R
  results/
    models/                 # saved fitted model objects (.rds)
    tables/                 # exported summaries
    figures/                # exported plots
  paper/
    Manuscript_revised.docx # put your manuscript here (optional)
```

---

## Setup

### R packages

These scripts use:

- `tidyverse`, `dplyr`, `ggplot2`
- `MCMCglmm`, `coda`
- `brms` (+ `cmdstanr` or `rstan`), `loo`
- `lme4`, `lmerTest`, `MuMIn`, `car` (for classical comparisons)
- `rptR`
- `plot3D`, `plotly` (optional 3D visualization)

Install missing packages as needed:
```r
install.packages(c("tidyverse","MCMCglmm","coda","MuMIn","lme4","lmerTest","car","rptR","plot3D","plotly","loo"))
install.packages("brms")
```

For **brms**, you also need a Stan backend:
- recommended: `cmdstanr` + CmdStan

---

## How to run (recommended order)

1) Edit the paths at the top of scripts in `scripts/`:
   - `PATH_INTERVAL_DATA` (your consecutive-year female interval data)
   - `PATH_NEST_DATA` (your nest timing data)

2) Run scripts in order:
- `scripts/01_interval_prepare_data.R`
- `scripts/02_interval_mcmcglmm.R`
- `scripts/03_interval_brms.R`
- `scripts/04_nest_prepare_data.R`
- `scripts/05_nest_mcmcglmm_reaction_norms.R`
- `scripts/06_diagnostics_plots.R`
- `scripts/07_repeatability_rptR.R`
- `scripts/08_brms_migration_climate_models.R`

All outputs are written under `results/`.

---

## Notes on modeling choices (matches manuscript)

- Interval model: ΔEggDate ~ ΔTemp + age-category + latitude with random intercepts for ID and location.
- Nest timing model: within–between centering for age and temperature; random intercepts + unstructured random slopes
  for age and temperature by individual; random intercept for location.

See manuscript methods for details and rationale (e.g., why Year random intercept may be redundant when temperature covariates
already capture interannual variation).

---

## Reproducibility tips

- Save session information:
```r
sessionInfo()
```
- If you want fully pinned versions, use `renv::init()` and commit the `renv.lock`.

---

## License

Add your preferred license (e.g., MIT) before making the repository public.
