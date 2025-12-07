# 01_discover_genres.R - Automatically discover genres from Wikipedia

library(tidyverse)
library(httr)
library(jsonlite)

message("Discovering electronic music genres from Wikipedia...")

# Function to get category members
get_category_members <- function(category_name, max_results = 100) {
  base_url <- "https://en.wikipedia.org/w/api.php"
  
  params <- list(
    action = "query",
    list = "categorymembers",
    cmtitle = paste0("Category:", category_name),
    cmlimit = max_results,
    cmtype = "page",
    format = "json"
  )
  
  response <- GET(base_url, query = params)
  
  if (status_code(response) != 200) {
    message("Error fetching category: ", category_name)
    return(tibble())
  }
  
  content <- content(response, "text") %>% fromJSON()
  
  if (is.null(content$query$categorymembers)) {
    return(tibble())
  }
  
  tibble(
    page_title = content$query$categorymembers$title,
    page_id = content$query$categorymembers$pageid
  )
}

# Categories to explore
main_categories <- c(
  "Electronic_music_genres",
  "Techno",
  "House_music",
  "Trance_music"
)

# Get all genres
all_genres <- map_df(main_categories, function(cat) {
  message("Fetching from category: ", cat)
  Sys.sleep(1)
  get_category_members(cat, max_results = 50)
})

# Clean up
all_genres <- all_genres %>%
  distinct(page_title, .keep_all = TRUE) %>%
  filter(!str_detect(page_title, "^List of|^Category:|^Portal:")) %>%
  mutate(url_title = str_replace_all(page_title, " ", "_"))

write_csv(all_genres, "data/raw/discovered_genres.csv")

message("\n✓ Found ", nrow(all_genres), " genre pages")
message("Next: Run 02_scrape_discovered_genres.R")