# 05_create_network.R - Build genre network from stylistic origins

library(tidyverse)
library(igraph)

genres_clean <- read_csv("data/processed/genres_clean.csv", show_col_types = FALSE)

message("Creating genre network...")

# Parse genre lists
parse_genre_list <- function(text) {
  if (is.na(text) || text == "") return(character(0))
  
  cleaned <- text %>%
    str_remove_all("\\[\\d+\\]") %>%
    str_replace_all("\\n", ", ") %>%
    str_remove_all("\\[\\[|\\]\\]") %>%
    str_remove_all("\\([^)]*\\)") %>%
    str_split(",|/|\\sand\\s") %>%
    .[[1]] %>%
    str_trim() %>%
    .[. != ""] %>%
    str_to_title()
  
  return(cleaned)
}

# Create edges
create_edges <- function(genre, origins_text) {
  parent_genres <- parse_genre_list(origins_text)
  
  if (length(parent_genres) == 0) {
    return(tibble(from = character(), to = character()))
  }
  
  tibble(
    from = parent_genres,
    to = rep(genre, length(parent_genres))
  )
}

# Build edge list
genre_edges <- genres_clean %>%
  filter(!is.na(stylistic_origins)) %>%
  rowwise() %>%
  mutate(edges = list(create_edges(genre, stylistic_origins))) %>%
  ungroup() %>%
  filter(map_lgl(edges, ~nrow(.x) > 0)) %>%
  unnest(edges) %>%
  filter(!is.na(from), !is.na(to), from != "", to != "") %>%
  select(from, to) %>%
  distinct()

write_csv(genre_edges, "data/processed/genre_edges.csv")

# Create network
genre_network <- graph_from_data_frame(genre_edges, directed = TRUE)
saveRDS(genre_network, "data/processed/genre_network.rds")

# Statistics
message("\n=== Network Statistics ===")
message("✓ ", vcount(genre_network), " unique genres")
message("✓ ", ecount(genre_network), " relationships")

message("\n=== Top Parent Genres ===")
genre_edges %>%
  count(from, sort = TRUE) %>%
  head(10) %>%
  print()

message("\nNext: Run 06_visualize.R")