# 02_scrape_discovered_genres.R - Scrape Wikipedia pages

library(tidyverse)
library(rvest)

all_genres <- read_csv("data/raw/discovered_genres.csv", show_col_types = FALSE)

message("Scraping ", nrow(all_genres), " genre pages...")

# Scraping function
scrape_genre <- function(page_title) {
  url <- paste0("https://en.wikipedia.org/wiki/", 
                str_replace_all(page_title, " ", "_"))
  
  Sys.sleep(runif(1, 0.5, 1.0))  # Polite scraping
  
  tryCatch({
    page <- read_html(url)
    infobox <- page %>% html_nodes(".infobox") %>% html_table()
    
    list(
      genre = page_title,
      has_infobox = length(infobox) > 0,
      infobox_data = if(length(infobox) > 0) infobox[[1]] else NULL
    )
  }, error = function(e) {
    list(genre = page_title, has_infobox = FALSE, infobox_data = NULL)
  })
}

# Scrape all
results <- map(all_genres$page_title, scrape_genre, .progress = TRUE)

# Convert to tibble
genres_raw <- tibble(
  genre = map_chr(results, "genre"),
  has_infobox = map_lgl(results, "has_infobox"),
  infobox_data = map(results, "infobox_data")
)

saveRDS(genres_raw, "data/raw/genres_raw.rds")

message("\n✓ Scraped ", nrow(genres_raw), " genres")
message("✓ ", sum(genres_raw$has_infobox), " with infoboxes")
message("Next: Run 03_extract_data.R")