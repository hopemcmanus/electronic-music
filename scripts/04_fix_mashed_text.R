# 04_fix_mashed_text.R - Fix genres with no separators

library(tidyverse)

genres_clean <- read_csv("data/processed/genres_clean.csv", show_col_types = FALSE)

message("Fixing mashed text entries...")

# Manual fixes from Wikipedia
fixes <- tribble(
  ~genre, ~fixed_stylistic_origins,
  
  "Ambient music", "Background music, beautiful music, drone, dub, easy listening, electronic, experimental, impressionist, krautrock, musique concrète, new age, new-age, space",
  "Deconstructed club", "Club music, experimental",
  "Downtempo", "Electronic, ambient, Bristol sound, hip hop",
  "Dreampunk", "Ambient, electronic, film score, vaporwave, liquid funk",
  "Drift phonk", "Hip hop, Memphis rap, electronic",
  "Drone music", "Minimalist, ambient, experimental",
  "Dub music", "Reggae, ska, electronic",
  "Glitch (music)", "Electronic, experimental, IDM",
  "Industrial metal", "Industrial, heavy metal, thrash metal",
  "Maidcore", "Electronic music, post-rock, anime music",
  "Nightcore", "Eurodance, happy hardcore, J-pop, trance",
  "Nu jazz", "Jazz, electronic, funk, hip hop",
  "Psybient", "Trance, psychedelia, Goa trance, ambient, world music",
  "Techno", "House, electro, synth-pop, hi-NRG, EBM, Eurodisco, Italo disco, post-disco",
  "Acid (electronic music)", "Chicago house, techno, trance",
  "Ambient techno", "Techno, ambient house, ambient, new age, chill-out",
  "Electro-industrial", "EBM, post-industrial"
)

# Apply fixes
genres_fixed <- genres_clean %>%
  left_join(fixes, by = "genre") %>%
  mutate(
    stylistic_origins = if_else(
      !is.na(fixed_stylistic_origins),
      fixed_stylistic_origins,
      stylistic_origins
    )
  ) %>%
  select(-fixed_stylistic_origins)

write_csv(genres_fixed, "data/processed/genres_clean.csv")

message("✓ Fixed ", nrow(fixes), " entries")
message("Next: Run 05_create_network.R")