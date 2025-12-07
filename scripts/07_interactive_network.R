# 07_interactive_network.R - Interactive network with Wikipedia links

library(tidyverse)
library(igraph)
library(visNetwork)

# Load network
genre_network <- readRDS("data/processed/genre_network.rds")

message("Creating interactive network...")

# Convert igraph to visNetwork format
nodes <- data.frame(
  id = V(genre_network)$name,
  label = V(genre_network)$name,
  title = paste0("<b>", V(genre_network)$name, "</b><br>Click to visit Wikipedia"),
  value = degree(genre_network),  # Size by degree
  color = "steelblue",
  # Create Wikipedia URLs
  url = paste0("https://en.wikipedia.org/wiki/", 
               str_replace_all(V(genre_network)$name, " ", "_"))
)

edges <- data.frame(
  from = ends(genre_network, E(genre_network))[,1],
  to = ends(genre_network, E(genre_network))[,2],
  arrows = "to",
  color = list(color = "gray", opacity = 0.3)
)

# Create interactive network
vis <- visNetwork(nodes, edges, width = "100%", height = "800px") %>%
  visNodes(
    scaling = list(min = 10, max = 40),
    font = list(size = 14)
  ) %>%
  visEdges(
    arrows = list(to = list(enabled = TRUE, scaleFactor = 0.5)),
    smooth = list(type = "continuous")
  ) %>%
  visPhysics(
    stabilization = TRUE,
    barnesHut = list(gravitationalConstant = -8000, springLength = 200)
  ) %>%
  visInteraction(
    navigationButtons = TRUE,
    hover = TRUE,
    tooltipDelay = 100
  ) %>%
  visOptions(
    highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
    nodesIdSelection = TRUE
  ) %>%
  visEvents(click = "function(nodes) {
    if (nodes.nodes.length > 0) {
      var nodeId = this.body.data.nodes.get(nodes.nodes[0]).id;
      var url = this.body.data.nodes.get(nodes.nodes[0]).url;
      window.open(url, '_blank');
    }
  }")

# Save as HTML
visSave(vis, "output/interactive_genre_network.html")

message("\n✓ Interactive network saved to: output/interactive_genre_network.html")
message("✓ Open in browser - click any node to visit Wikipedia!")