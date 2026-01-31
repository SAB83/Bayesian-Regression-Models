# NestWatch → Traits → Phylogeny → Parasites pipeline (R)

This repository provides a **data-free, reproducible pipeline** to prepare NestWatch nesting attempts data for
phylogenetic Bayesian models (MCMCglmm), including:

- Cleaning NestWatch attempts (species name filtering, year sanity checks)
- Parsing dates and computing DOY
- Joining eBird taxonomy to add scientific names (space + underscore formats)
- Joining temperature summaries by Attempt ID
- Creating nest-level parasite presence flags from checks data (egg vs young)
- Joining brain/trait data (e.g., body mass, phylogenetic residuals)
- Matching species to a phylogeny, pruning the tree to the analysis set
- PCA on temperature variables (PC1 → `ColderVariableTemp`)
- Phylogenetic MCMCglmm models for:
  1) egg parasite presence (categorical)
  2) young parasite presence (categorical)
  3) fledging count (poisson)
- Diagnostics export (Geweke z-scores)

## No public data
**No datasets are included in this repo**. You point the pipeline to your local files via `config/config.yml`,
which is ignored by git.

## Setup

1) Copy the example config and edit paths:

```bash
cp config/config_example.yml config/config.yml
```

2) Install required R packages (examples):

```r
install.packages(c("dplyr","stringr","readr","yaml","psych","ape","coda"))
install.packages("MCMCglmm")
```

## Pipeline overview (what each script does)

1. **01_read_attempts_clean_species.R**
   - Read attempts CSV, turn blanks → NA, report counts
   - Drop ambiguous species labels (`sp.`, hybrids ` x `, slash names `/`)
   - Year sanity checks (out of range → NA)
   - Output: `outputs/intermediate/attempts_clean_step1.csv`

2. **02_parse_dates_add_doy.R**
   - Standardize date strings to `YYYY-MM-DD`
   - Compute DOY without `as.Date`
   - Output: `outputs/intermediate/attempts_with_doy.csv`

3. **03_add_scientific_names.R**
   - Join eBird taxonomy by common name
   - Add:
     - `ScientificName_sp` (Genus species)
     - `ScientificName_us` (Genus_species)
   - Output: `outputs/intermediate/attempts_with_scientific.csv`

4. **04_join_temperature.R**
   - Standardize Attempt ID column names
   - Left join temperature summaries (mean/min/max/sd/var/range)
   - Output: `outputs/intermediate/attempts_with_temp.csv`

5. **05_parasite_flags.R**
   - Standardize Attempt ID in checks data
   - Robustly match parasite column names across punctuation differences
   - Create nest-level binary outcomes:
     - `egg_par_positive`
     - `young_par_positive`
   - Output: `outputs/intermediate/attempts_with_parasite.csv`

6. **06_join_brain_data.R**
   - Load `BrainData` from a local `.Rdata`
   - Join by underscore species name
   - Output: `outputs/intermediate/attempts_with_brain.csv`

7. **07_tree_match_and_prune.R**
   - Load `mytree` from a local `.Rdata`
   - Map data species to tree tip labels robustly (binomial + normalize)
   - Drop unmatched rows and prune the tree to matched tips
   - Output: `outputs/intermediate/phylo_objects.rds`

8. **08_temp_pca.R**
   - PCA on temperature variables
   - Set `ColderVariableTemp = -1 * PC1`
   - Output: `outputs/final/nestwatch_analysis_ready.rds`

9. **09_phylo_mcmcglmm_models.R**
   - Build final modeling dataset
   - Align species factor levels with tree tips
   - Build `Ainv` from pruned tree
   - Fit 3 phylogenetic MCMCglmm models
   - Output: `outputs/models/*.rds`, summaries in `outputs/tables/`

10. **10_diagnostics_export.R**
    - Export Geweke diagnostics for Sol/VCV
    - Output: `outputs/tables/diagnostics_*.txt`

## How to run

Run in order from the repo root:

```r
source("scripts/01_read_attempts_clean_species.R")
source("scripts/02_parse_dates_add_doy.R")
source("scripts/03_add_scientific_names.R")
source("scripts/04_join_temperature.R")
source("scripts/05_parasite_flags.R")
source("scripts/06_join_brain_data.R")
source("scripts/07_tree_match_and_prune.R")
source("scripts/08_temp_pca.R")
source("scripts/09_phylo_mcmcglmm_models.R")
source("scripts/10_diagnostics_export.R")
```

## Notes / assumptions

- Attempts data includes `Species.Name` and `Year`.
- Attempt identifiers begin with `Attempt` (e.g., `Attempt.ID`, `Attempt ID`). Scripts find them via `grep("^Attempt", ...)`.
- Checks data contains brood parasite fields; scripts match them robustly even if dots/spaces differ.
- Brain data is loaded from an `.Rdata` file that provides an object named `BrainData`.
- Tree is loaded from an `.Rdata` file that provides an object named `mytree`.
