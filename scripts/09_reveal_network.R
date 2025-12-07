# 09_reveal_network.R - Progressive revelation starting from seeds

library(tidyverse)
library(igraph)
library(visNetwork)

genre_network <- readRDS("data/processed/genre_network.rds")

message("Creating progressive reveal network...")

# Seed genres
seeds <- c("House Music", "Techno")

# Get direct children of seeds
get_children <- function(parent) {
  edge_list <- as_edgelist(genre_network, names = TRUE)
  children <- edge_list[edge_list[,1] == parent, 2]
  return(children)
}

initial_children <- unique(unlist(lapply(seeds, get_children)))

# Initially visible nodes: seeds + their immediate children
visible_nodes <- c(seeds, initial_children)

# Create nodes
all_nodes <- V(genre_network)$name
nodes <- data.frame(
  id = all_nodes,
  label = all_nodes,
  title = paste0("<b>", all_nodes, "</b><br>", 
                 ifelse(all_nodes %in% seeds, "SEED - Click to expand",
                        ifelse(all_nodes %in% initial_children, "Click to expand children", 
                               "Click parent to reveal"))),
  value = degree(genre_network) + 5,
  url = paste0("https://en.wikipedia.org/wiki/", str_replace_all(all_nodes, " ", "_")),
  hidden = !all_nodes %in% visible_nodes,
  color = case_when(
    all_nodes %in% seeds ~ "darkblue",
    all_nodes %in% initial_children ~ "steelblue",
    TRUE ~ "lightgray"
  ),
  font.size = ifelse(all_nodes %in% seeds, 20, 14)
)

# Create edges
edge_list <- as_edgelist(genre_network, names = TRUE)
edges <- data.frame(
  from = edge_list[,1],
  to = edge_list[,2],
  arrows = "to",
  hidden = !(edge_list[,1] %in% visible_nodes & edge_list[,2] %in% visible_nodes)
)

# Network
vis <- visNetwork(nodes, edges, width = "100%", height = "900px") %>%
  visNodes(
    scaling = list(min = 10, max = 40),
    font = list(size = 14, bold = TRUE)
  ) %>%
  visEdges(
    arrows = list(to = list(enabled = TRUE)),
    smooth = list(type = "continuous")
  ) %>%
  visPhysics(
    solver = "forceAtlas2Based",
    forceAtlas2Based = list(gravitationalConstant = -50, springLength = 100)
  ) %>%
  visInteraction(navigationButtons = TRUE, hover = TRUE) %>%
  visOptions(highlightNearest = TRUE) %>%
  visEvents(
    # Single click: reveal children
    click = "function(params) {
      if (params.nodes.length > 0) {
        var clickedNode = params.nodes[0];
        var connectedNodes = this.getConnectedNodes(clickedNode, 'to');
        var allEdges = this.body.data.edges.get();
        
        var nodesToShow = [];
        var edgesToShow = [];
        
        // Show all children of clicked node
        for (var i = 0; i < connectedNodes.length; i++) {
          nodesToShow.push({id: connectedNodes[i], hidden: false});
        }
        
        // Show edges from clicked node to children
        for (var i = 0; i < allEdges.length; i++) {
          if (allEdges[i].from === clickedNode) {
            edgesToShow.push({id: allEdges[i].id, hidden: false});
          }
        }
        
        this.body.data.nodes.update(nodesToShow);
        this.body.data.edges.update(edgesToShow);
      }
    }",
    
    # Double click: Wikipedia
    doubleClick = "function(params) {
      if (params.nodes.length > 0) {
        var node = this.body.data.nodes.get(params.nodes[0]);
        window.open(node.url, '_blank');
      }
    }"
  )

visSave(vis, "output/reveal_genre_network.html")

message("\n✓ Progressive reveal network created!")
message("✓ Starting with: ", paste(seeds, collapse = " and "))
message("✓ Single click node → Reveal its children")
message("✓ Double click → Wikipedia")