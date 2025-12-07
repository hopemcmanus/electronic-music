# 08_expandable_network.R - Click to expand genre families

library(tidyverse)
library(igraph)
library(visNetwork)

genre_network <- readRDS("data/processed/genre_network.rds")

message("Creating expandable network...")

# Define seed genres (what shows initially)
seed_genres <- c("House Music", "Techno", "Trance", "Ambient", "Drum And Bass")

# Get all nodes
all_nodes <- V(genre_network)$name

# Create node data with hidden/visible status
nodes <- data.frame(
  id = all_nodes,
  label = all_nodes,
  title = paste0("<b>", all_nodes, "</b><br>Click to expand/collapse"),
  value = degree(genre_network),
  color = ifelse(all_nodes %in% seed_genres, "steelblue", "lightgray"),
  url = paste0("https://en.wikipedia.org/wiki/", str_replace_all(all_nodes, " ", "_")),
  # Initially hide all except seeds
  hidden = !all_nodes %in% seed_genres,
  # Group by whether it's a seed
  group = ifelse(all_nodes %in% seed_genres, "seed", "derivative")
)

# Edge data
edge_list <- as_edgelist(genre_network, names = TRUE)
edges <- data.frame(
  from = edge_list[,1],
  to = edge_list[,2],
  arrows = "to",
  color = list(color = "gray", opacity = 0.3),
  # Hide edges where target is hidden
  hidden = !edge_list[,2] %in% seed_genres
)

# Create network
vis <- visNetwork(nodes, edges, width = "100%", height = "800px") %>%
  visNodes(
    scaling = list(min = 15, max = 50),
    font = list(size = 16)
  ) %>%
  visGroups(
    groupname = "seed",
    color = list(background = "steelblue", border = "darkblue", highlight = "orange")
  ) %>%
  visGroups(
    groupname = "derivative", 
    color = list(background = "lightblue", border = "gray")
  ) %>%
  visEdges(
    arrows = list(to = list(enabled = TRUE, scaleFactor = 0.5)),
    smooth = TRUE
  ) %>%
  visPhysics(
    stabilization = TRUE,
    barnesHut = list(gravitationalConstant = -5000, springLength = 150)
  ) %>%
  visInteraction(
    navigationButtons = TRUE,
    hover = TRUE
  ) %>%
  visOptions(
    highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE)
  ) %>%
  visEvents(
    # Click to expand/collapse
    click = "function(params) {
      if (params.nodes.length > 0) {
        var clickedNode = params.nodes[0];
        var connectedNodes = this.getConnectedNodes(clickedNode);
        var connectedEdges = this.getConnectedEdges(clickedNode);
        
        // Toggle visibility of connected nodes
        var updates = [];
        for (var i = 0; i < connectedNodes.length; i++) {
          var nodeId = connectedNodes[i];
          var currentNode = this.body.data.nodes.get(nodeId);
          updates.push({
            id: nodeId,
            hidden: !currentNode.hidden
          });
        }
        
        // Toggle visibility of connected edges  
        var edgeUpdates = [];
        for (var i = 0; i < connectedEdges.length; i++) {
          var edgeId = connectedEdges[i];
          var currentEdge = this.body.data.edges.get(edgeId);
          edgeUpdates.push({
            id: edgeId,
            hidden: !currentEdge.hidden
          });
        }
        
        this.body.data.nodes.update(updates);
        this.body.data.edges.update(edgeUpdates);
      }
    }",
    
    # Double-click to open Wikipedia
    doubleClick = "function(params) {
      if (params.nodes.length > 0) {
        var nodeId = params.nodes[0];
        var node = this.body.data.nodes.get(nodeId);
        window.open(node.url, '_blank');
      }
    }"
  ) %>%
  visLegend(
    addNodes = list(
      list(label = "Seed Genre (Click to expand)", shape = "dot", color = "steelblue", size = 20),
      list(label = "Derivative Genre", shape = "dot", color = "lightblue", size = 15)
    ),
    useGroups = FALSE
  )

# Save
visSave(vis, "output/expandable_genre_network.html")

message("\n✓ Expandable network saved!")
message("✓ Single click → Expand/collapse connections")
message("✓ Double click → Open Wikipedia")
message("\nStarting view shows: ", paste(seed_genres, collapse = ", "))