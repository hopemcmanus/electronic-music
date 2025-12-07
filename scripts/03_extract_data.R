# 03_extract_data.R - Extract fields from infoboxes

library(tidyverse)

genres_raw <- readRDS("data/raw/genres_raw.rds")

message("Extracting data from infoboxes...")

# Extraction function
extract_field <- function(infobox_data, field_name) {
  tryCatch({
    if (is.null(infobox_data)) return(NA_character_)
    if (!is.data.frame(infobox_data)) return(NA_character_)
    if (nrow(infobox_data) == 0) return(NA_character_)
    if (ncol(infobox_data) < 2) return(NA_character_)
    
    field_col <- infobox_data[[1]]
    value_col <- infobox_data[[2]]
    
    matches <- grep(field_name, field_col, ignore.case = TRUE)
    
    if (length(matches) == 0) return(NA_character_)
    
    value <- value_col[matches[1]]
    
    if (is.na(value)) return(NA_character_)
    
    cleaned <- trimws(value)
    if (cleaned == "") return(NA_character_)
    
    return(cleaned)
    
  }, error = function(e) {
    return(NA_character_)
  })
}

# Extract fields
genres_clean <- genres_raw %>%
  filter(has_infobox == TRUE) %>%
  mutate(
    stylistic_origins = map_chr(infobox_data, ~extract_field(.x, "Stylistic origins")),
    cultural_origins = map_chr(infobox_data, ~extract_field(.x, "Cultural origins")),
    derivative_forms = map_chr(infobox_data, ~extract_field(.x, "Derivative forms")),
    subgenres = map_chr(infobox_data, ~extract_field(.x, "Subgenres")),
    fusion_genres = map_chr(infobox_data, ~extract_field(.x, "Fusion genres")),
    other_names = map_chr(infobox_data, ~extract_field(.x, "Other names"))
  ) %>%
  select(-infobox_data)

write_csv(genres_clean, "data/processed/genres_clean.csv")

# Report
message("\n=== Extraction Results ===")
fields <- c("stylistic_origins", "cultural_origins", "derivative_forms", 
            "subgenres", "fusion_genres", "other_names")

for (field in fields) {
  n <- sum(!is.na(genres_clean[[field]]))
  pct <- round(100 * n / nrow(genres_clean), 1)
  message(sprintf("%-20s: %2d/%d (%s%%)", field, n, nrow(genres_clean), pct))
}

# Check for mashed text
problematic <- genres_clean %>%
  filter(!is.na(stylistic_origins)) %>%
  mutate(
    has_camelCase = str_detect(stylistic_origins, "[a-z][A-Z]"),
    very_long_word = str_detect(stylistic_origins, "\\b\\w{20,}\\b")
  ) %>%
  filter(has_camelCase | very_long_word)

message("\n✓ Genres with mashed text: ", nrow(problematic))
if (nrow(problematic) > 0) {
  message("Next: Run 04_fix_mashed_text.R")
} else {
  message("Next: Run 05_create_network.R")
}