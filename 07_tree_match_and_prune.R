# 07_tree_match_and_prune.R
# Purpose:
# - Match dataset species to phylogeny tip labels robustly
# - Drop unmatched rows
# - Prune the tree to the dataset species
#
# Inputs:
# - outputs/intermediate/attempts_with_brain.csv
# - cfg$paths$tree_rdata (loads mytree)
# Output:
# - outputs/intermediate/phylo_objects.rds (dat_tree + pruned_tree + mytree)

source("scripts/00_setup.R")
suppressPackageStartupMessages({ library(readr); library(dplyr); library(ape) })

dat <- readr::read_csv("outputs/intermediate/attempts_with_brain.csv", show_col_types = FALSE)

load(cfg$paths$tree_rdata) # must create mytree object
if (!exists("mytree")) stop("mytree not found after loading tree_rdata.")

require_cols(dat, c("Species"), "attempts_with_brain")

dat_binom <- to_binom_us(dat$Species)
dat_key   <- norm_key(dat_binom)

tree_binom <- to_binom_us(mytree$tip.label)
tree_key   <- norm_key(tree_binom)

overlap_n <- sum(unique(na.omit(dat_key)) %in% unique(tree_key))
message("Tree tips: ", length(mytree$tip.label),
        " | Data binomial: ", length(unique(na.omit(dat_binom))),
        " | Overlap: ", overlap_n)

if (overlap_n == 0) stop("Zero overlap between tree and data after normalization.")

tip_lookup <- setNames(mytree$tip.label, tree_key)
dat$Species_tree <- unname(tip_lookup[dat_key])

dat_tree <- dat %>% filter(!is.na(Species_tree))

tips_to_rm <- setdiff(mytree$tip.label, unique(dat_tree$Species_tree))
pruned_tree <- ape::drop.tip(mytree, tips_to_rm)

message("Rows after tree match: ", nrow(dat_tree))
message("Pruned tips: ", length(pruned_tree$tip.label))

saveRDS(list(dat_tree=dat_tree, pruned_tree=pruned_tree, mytree=mytree),
        "outputs/intermediate/phylo_objects.rds")
