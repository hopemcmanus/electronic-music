# 07_plotly_network.R - Interactive with Plotly

library(tidyverse)
library(igraph)
library(plotly)

genre_network <- readRDS("data/processed/genre_network.rds")

# Get layout
layout <- layout_with_fr(genre_network)

# Create edge traces
edge_shapes <- list()
for(i in 1:ecount(genre_network)) {
  edge <- ends(genre_network, E(genre_network)[i])
  
  edge_shapes[[i]] <- list(
    type = "line",
    x0 = layout[edge[1],1],
    y0 = layout[edge[1],2],
    x1 = layout[edge[2],1],
    y1 = layout[edge[2],2],
    line = list(color = "rgba(150,150,150,0.3)", width = 0.5)
  )
}

# Node data
node_data <- data.frame(
  x = layout[,1],
  y = layout[,2],
  name = V(genre_network)$name,
  degree = degree(genre_network),
  url = paste0("https://en.wikipedia.org/wiki/", 
               str_replace_all(V(genre_network)$name, " ", "_"))
)

# Create plot
p <- plot_ly(node_data) %>%
  add_markers(
    x = ~x, 
    y = ~y,
    text = ~paste0(name, "<br>Connections: ", degree, "<br>Click to visit Wikipedia"),
    hoverinfo = "text",
    marker = list(
      size = ~sqrt(degree) * 5,
      color = "steelblue",
      line = list(width = 1, color = "white")
    ),
    customdata = ~url
  ) %>%
  layout(
    title = "Electronic Music Genre Network (Click nodes to visit Wikipedia)",
    shapes = edge_shapes,
    xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    hovermode = "closest"
  ) %>%
  htmlwidgets::onRender("
    function(el, x) {
      el.on('plotly_click', function(data) {
        var url = data.points[0].customdata;
        window.open(url, '_blank');
      });
    }
  ")

# Save
htmlwidgets::saveWidget(p, "output/plotly_genre_network.html", selfcontained = TRUE)

message("✓ Plotly network saved to: output/plotly_genre_network.html")