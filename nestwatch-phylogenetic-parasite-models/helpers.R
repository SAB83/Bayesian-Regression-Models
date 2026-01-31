suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(yaml)
})

# Fail fast if required columns are missing
require_cols <- function(df, cols, name="data") {
  miss <- setdiff(cols, names(df))
  if (length(miss) > 0) stop("Missing columns in ", name, ": ", paste(miss, collapse=", "))
  invisible(TRUE)
}

# Create one or more directories safely
dir_create <- function(...) {
  for (p in c(...)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

# Convert any name to binomial underscore "Genus_species"
to_binom_us <- function(x) {
  x <- str_squish(as.character(x))
  x <- str_replace_all(x, " +", "_")
  parts <- str_split(x, "_")
  vapply(parts, function(p) if (length(p) >= 2) paste(p[1], p[2], sep="_") else NA_character_, character(1))
}

# Normalize for robust matching across punctuation/case differences
norm_key <- function(x) {
  x <- tolower(as.character(x))
  gsub("[^a-z_]", "", x)
}

# Robust MM/DD + Year -> YYYY-MM-DD + DOY (without as.Date)
build_date_and_doy <- function(md_vec, year_vec) {
  n <- length(md_vec)
  out_date <- rep(NA_character_, n)
  out_doy  <- rep(NA_integer_, n)

  md_chr <- str_squish(as.character(md_vec))
  md_chr <- str_replace_all(md_chr, "-", "/")
  md_chr <- str_replace(md_chr, " .*", "") # remove time

  for (i in seq_len(n)) {
    md <- md_chr[i]
    yr <- suppressWarnings(as.integer(year_vec[i]))
    if (is.na(md) || md == "" || is.na(yr)) next

    parts <- str_split(md, "/", simplify = TRUE)
    if (ncol(parts) < 2) next

    m <- suppressWarnings(as.integer(parts[1]))
    d <- suppressWarnings(as.integer(parts[2]))

    if (is.na(m) || is.na(d) || m < 1 || m > 12 || d < 1 || d > 31) next

    out_date[i] <- sprintf("%04d-%02d-%02d", yr, m, d)

    month_len <- c(31,28,31,30,31,30,31,31,30,31,30,31)
    leap <- (yr %% 4 == 0 && yr %% 100 != 0) || (yr %% 400 == 0)
    if (leap) month_len[2] <- 29
    out_doy[i] <- if (m == 1) d else sum(month_len[1:(m-1)]) + d
  }

  list(date = out_date, doy = out_doy)
}
