suppressPackageStartupMessages({
  library(yaml)
  source("R/helpers.R")
})

cfg <- yaml::read_yaml("config/config.yml")

dir_create(
  "outputs/intermediate",
  "outputs/final",
  "outputs/models",
  "outputs/tables",
  "outputs/figures"
)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

CORES <- cfg$options$cores %||% 2
YEAR_MIN <- cfg$options$year_min %||% 1900
YEAR_MAX <- cfg$options$year_max %||% 2100

message("Setup ok. CORES=", CORES, " YEAR_RANGE=", YEAR_MIN, "-", YEAR_MAX)
