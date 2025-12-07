# 09_reveal_network.R - WORKING VERSION

library(tidyverse)
library(igraph)
library(visNetwork)

genre_network <- readRDS("data/processed/genre_network.rds")

message("Creating progressive reveal network...")

# ALL nodes and edges (we'll control visibility)
all_nodes <- V(genre_network)$name
edge_list <- as_edgelist(genre_network, names = TRUE)

# Seeds to start with
seeds <- c("House Music", "Techno")

# Mark which nodes are initially visible
nodes <- data.frame(
  id = all_nodes,
  label = all_nodes,
  title = paste0("<b>", all_nodes, "</b><br>Degree: ", degree(genre_network)),
  value = degree(genre_network) * 2,
  url = paste0("https://en.wikipedia.org/wiki/", str_replace_all(all_nodes, " ", "_")),
  color = ifelse(all_nodes %in% seeds, "#1f77b4", "#aec7e8"),
  font.size = ifelse(all_nodes %in% seeds, 20, 14),
  hidden = !all_nodes %in% seeds  # Start with only seeds visible
)

# Edges - hide all initially
edges <- data.frame(
  from = edge_list[,1],
  to = edge_list[,2],
  arrows = "to",
  color = "gray",
  hidden = TRUE  # Start with all edges hidden
)

# Add button controls
vis <- visNetwork(nodes, edges, width = "100%", height = "800px") %>%
  visPhysics(
    solver = "forceAtlas2Based",
    forceAtlas2Based = list(
      gravitationalConstant = -100,
      springLength = 150,
      springConstant = 0.05
    ),
    stabilization = list(iterations = 100)
  ) %>%
  visInteraction(
    navigationButtons = TRUE,
    hover = TRUE,
    tooltipDelay = 200
  ) %>%
  visNodes(
    scaling = list(min = 15, max = 40)
  ) %>%
  visEdges(
    arrows = list(to = list(enabled = TRUE, scaleFactor = 0.8))
  )

# Save basic version first
visSave(vis, "output/reveal_genre_network_basic.html")

message("\n✓ Basic network created: output/reveal_genre_network_basic.html")
message("\nNow creating version with expand buttons...")

# Version 2: With manual expand buttons
nodes_expandable <- nodes %>%
  mutate(
    # Add data attribute for children
    group = ifelse(id %in% seeds, "seed", "child")
  )

vis2 <- visNetwork(nodes_expandable, edges, width = "100%", height = "800px") %>%
  visGroups(groupname = "seed", color = "#1f77b4", size = 30) %>%
  visGroups(groupname = "child", color = "#aec7e8", size = 20) %>%
  visPhysics(solver = "barnesHut") %>%
  visInteraction(navigationButtons = TRUE) %>%
  visOptions(
    manipulation = list(
      enabled = FALSE
    ),
    selectedNodes = list()
  )

visSave(vis2, "output/reveal_genre_network_v2.html")

message("✓ Version 2 created: output/reveal_genre_network_v2.html")

# Create HTML with custom controls
html_with_controls <- sprintf('
<!DOCTYPE html>
<html>
<head>
<title>Electronic Music Genre Explorer</title>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
  body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
  #mynetwork { width: 100%%; height: 700px; border: 1px solid #ddd; }
  #controls { margin-bottom: 10px; padding: 10px; background: #f5f5f5; }
  button { margin: 5px; padding: 10px 20px; font-size: 14px; cursor: pointer; }
  button:hover { background: #e0e0e0; }
  #info { margin-top: 10px; padding: 10px; background: #e3f2fd; }
</style>
</head>
<body>

<h2>Electronic Music Genre Explorer</h2>

<div id="controls">
  <button onclick="expandHouse()">🎵 Expand House Music</button>
  <button onclick="expandTechno()">🎛️ Expand Techno</button>
  <button onclick="expandAll()">🌐 Show All</button>
  <button onclick="reset()">🔄 Reset</button>
</div>

<div id="info">
  <b>Instructions:</b> Click buttons above to reveal genre families. Click any node to open Wikipedia.
</div>

<div id="mynetwork"></div>

<script>
// Nodes data
var nodesData = %s;

// Edges data  
var edgesData = %s;

var nodes = new vis.DataSet(nodesData);
var edges = new vis.DataSet(edgesData);

var container = document.getElementById("mynetwork");
var data = { nodes: nodes, edges: edges };

var options = {
  physics: {
    barnesHut: {
      gravitationalConstant: -8000,
      springLength: 200
    }
  },
  nodes: {
    shape: "dot",
    scaling: { min: 15, max: 40 }
  },
  edges: {
    arrows: { to: { enabled: true } },
    smooth: true
  },
  interaction: {
    hover: true,
    navigationButtons: true
  }
};

var network = new vis.Network(container, data, options);

// Click to open Wikipedia
network.on("click", function(params) {
  if (params.nodes.length > 0) {
    var nodeId = params.nodes[0];
    var node = nodes.get(nodeId);
    window.open(node.url, "_blank");
  }
});

// Get children of a node
function getChildren(parentId) {
  var children = [];
  var allEdges = edges.get();
  for (var i = 0; i < allEdges.length; i++) {
    if (allEdges[i].from === parentId) {
      children.push(allEdges[i].to);
      var childEdge = allEdges[i].id;
      edges.update({id: childEdge, hidden: false});
    }
  }
  return children;
}

function expandHouse() {
  var children = getChildren("House Music");
  children.forEach(function(childId) {
    nodes.update({id: childId, hidden: false});
  });
  nodes.update({id: "House Music", hidden: false});
}

function expandTechno() {
  var children = getChildren("Techno");
  children.forEach(function(childId) {
    nodes.update({id: childId, hidden: false});
  });
  nodes.update({id: "Techno", hidden: false});
}

function expandAll() {
  nodes.forEach(function(node) {
    nodes.update({id: node.id, hidden: false});
  });
  edges.forEach(function(edge) {
    edges.update({id: edge.id, hidden: false});
  });
}

function reset() {
  nodes.forEach(function(node) {
    if (node.id === "House Music" || node.id === "Techno") {
      nodes.update({id: node.id, hidden: false});
    } else {
      nodes.update({id: node.id, hidden: true});
    }
  });
  edges.forEach(function(edge) {
    edges.update({id: edge.id, hidden: true});
  });
}
</script>

</body>
</html>
', 
jsonlite::toJSON(nodes_expandable, dataframe = "rows"),
jsonlite::toJSON(edges, dataframe = "rows")
)

# Write HTML file
writeLines(html_with_controls, "output/reveal_genre_network.html")

message("\n✅ COMPLETE! Open: output/reveal_genre_network.html")
message("✓ Click 'Expand House Music' or 'Expand Techno' buttons")
message("✓ Click any node to open Wikipedia page")