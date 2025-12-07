# 10_hierarchical_network.R - Organized by levels

library(tidyverse)
library(igraph)
library(visNetwork)

genre_network <- readRDS("data/processed/genre_network.rds")

# Define hierarchy levels
level_0 <- c("House Music", "Techno")  # Root
level_1 <- c("Deep House", "Tech House", "Acid House", "Detroit Techno", "Minimal Techno")  # First children

all_nodes <- V(genre_network)$name

nodes <- data.frame(
  id = all_nodes,
  label = all_nodes,
  level = case_when(
    all_nodes %in% level_0 ~ 0,
    all_nodes %in% level_1 ~ 1,
    TRUE ~ 2
  ),
  color = case_when(
    all_nodes %in% level_0 ~ "darkblue",
    all_nodes %in% level_1 ~ "steelblue",
    TRUE ~ "lightblue"
  ),
  value = degree(genre_network),
  url = paste0("https://en.wikipedia.org/wiki/", str_replace_all(all_nodes, " ", "_"))
)

edge_list <- as_edgelist(genre_network, names = TRUE)
edges <- data.frame(from = edge_list[,1], to = edge_list[,2], arrows = "to")

vis <- visNetwork(nodes, edges) %>%
  visHierarchicalLayout(direction = "UD", sortMethod = "directed") %>%
  visNodes(size = 25) %>%
  visInteraction(navigationButtons = TRUE) %>%
  visEvents(
    click = "function(params) {
      if (params.nodes.length > 0) {
        var node = this.body.data.nodes.get(params.nodes[0]);
        window.open(node.url, '_blank');
      }
    }"
  )

visSave(vis, "output/hierarchical_genre_network.html")

message("✓ Hierarchical network created!")