# 06_visualise.R - Create network visualization

library(tidyverse)
library(igraph)
library(ggraph)

genre_network <- readRDS("data/processed/genre_network.rds")

message("Creating visualization...")

# Create plot
p <- ggraph(genre_network, layout = 'fr') +
  geom_edge_link(
    arrow = arrow(length = unit(2, 'mm')), 
    alpha = 0.2,
    color = "gray40",
    end_cap = circle(3, 'mm')
  ) +
  geom_node_point(
    aes(size = degree(genre_network)), 
    color = "steelblue",
    alpha = 0.8
  ) +
  geom_node_text(
    aes(label = name, size = degree(genre_network)), 
    repel = TRUE,
    max.overlaps = 30,
    segment.alpha = 0.3
  ) +
  scale_size_continuous(range = c(1.5, 6)) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5)
  ) +
  labs(
    title = "Electronic Music Genre Network",
    subtitle = sprintf("Based on Wikipedia Stylistic Origins (%d relationships, %d genres)",
                       ecount(genre_network), vcount(genre_network))
  )

ggsave("output/genre_network.png", p, width = 20, height = 16, dpi = 300)

message("\n✓ Visualization saved to: output/genre_network.png")
message("✓ Project complete!")