# 00_setup.R - Project setup
# Electronic Music Genre Network Analysis

library(tidyverse)
library(rvest)
library(httr)
library(jsonlite)
library(igraph)
library(ggraph)

# Create directories
dirs <- c("R", "data/raw", "data/processed", "output")
walk(dirs, ~dir.create(.x, recursive = TRUE, showWarnings = FALSE))

message("✓ Project setup complete!")
message("Next: Run 01_discover_genres.R")