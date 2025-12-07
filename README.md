# Electronic Music Genre Network Analysis

An automated R pipeline that discovers, scrapes, and visualizes electronic music genre relationships from Wikipedia.

## Project Overview

This project automatically builds a network graph of electronic music genres by:
  1. Discovering genres from Wikipedia categories
2. Scraping genre infoboxes
3. Extracting stylistic origin relationships
4. Creating network visualization

**Final Output:** Network diagram showing 291 relationships across 203 electronic music genres.

---
  
  ## Directory Structure
  ```
electronic-music-genres/
  ├── R/
  │   ├── 00_setup.R
│   ├── 01_discover_genres.R
│   ├── 02_scrape_discovered_genres.R
│   ├── 03_extract_data.R
│   ├── 04_fix_mashed_text.R
│   ├── 05_create_network.R
│   └── 06_visualize.R
├── data/
  │   ├── raw/
  │   │   ├── discovered_genres.csv        # List of genres from Wikipedia
│   │   └── genres_raw.rds                # Raw scraped infobox data
│   └── processed/
  │       ├── genres_clean.csv              # Cleaned extracted fields
│       ├── genre_edges.csv               # Parent-child relationships
│       └── genre_network.rds             # Network graph object
└── output/
  └── genre_network.png                 # Final visualization
```

---
  
  ## Installation
  ```r
install.packages(c("tidyverse", "rvest", "httr", "jsonlite", "igraph", "ggraph"))
```

---
  
  ## Running the Pipeline
  
  Execute scripts in order:
  ```r
source("R/00_setup.R")
source("R/01_discover_genres.R")
source("R/02_scrape_discovered_genres.R")
source("R/03_extract_data.R")
source("R/04_fix_mashed_text.R")
source("R/05_create_network.R")
source("R/06_visualize.R")
```

**Total runtime:** 5-10 minutes

---
  
  ## Script Details
  
  ### 00_setup.R - Project Initialization
  
  **Purpose:** Sets up project environment and directory structure.

**What it does:**
  - Loads all required R packages
- Creates project directories (R/, data/raw/, data/processed/, output/)
- Verifies package installation

**Runtime:** <1 second

---
  
  ### 01_discover_genres.R - Automated Genre Discovery
  
  **Purpose:** Automatically discovers electronic music genres from Wikipedia using the Wikipedia API.

**How it works:**
  1. Connects to Wikipedia's MediaWiki API
2. Queries four seed categories:
   - Electronic_music_genres (main category)
   - Techno (techno subgenres)
   - House_music (house subgenres)
   - Trance_music (trance subgenres)
3. For each category, retrieves up to 50 member pages
4. Filters out non-genre pages (lists, portals, category pages)
5. Removes duplicate pages found in multiple categories

**Key Function:**
```r
get_category_members(category_name, max_results = 100)
```
- Sends GET request to Wikipedia API
- Parses JSON response
- Returns tibble of page titles and IDs

**Output:** 
- `data/raw/discovered_genres.csv` (~89 genres discovered)

**Customization:**
```r
main_categories <- c(
  "Electronic_music_genres",
  "Drum_and_bass",          # Add DnB subgenres
  "Dubstep",                # Add dubstep variants
  "Ambient_music"           # Add ambient styles
)
```

**Runtime:** ~5 seconds

---

### 02_scrape_discovered_genres.R - Wikipedia Page Scraping

**Purpose:** Scrapes the actual Wikipedia pages for each discovered genre to extract infobox data.

**How it works:**
1. Loads genre list from step 1
2. For each genre:
   - Constructs Wikipedia URL
   - Downloads HTML page with `rvest::read_html()`
   - Searches for `.infobox` CSS class
   - Converts infobox HTML table to R dataframe
3. Implements polite scraping: random delays (0.5-1.0 seconds) between requests
4. Handles errors gracefully (network issues, missing pages, malformed HTML)
5. Displays progress bar during scraping

**Key Function:**
```r
scrape_genre(page_title)
```

**Why some genres lack infoboxes:**
- Disambiguation pages
- Redirect pages
- Pages without standardized infobox templates

**Output:**
- `data/raw/genres_raw.rds` (R object with raw infobox dataframes)
- Typical result: 66/89 genres have infoboxes

**Runtime:** 2-3 minutes

---

### 03_extract_data.R - Data Extraction from Infoboxes

**Purpose:** Extracts specific fields from the scraped infobox HTML tables.

**How it works:**
1. Searches infoboxes for these Wikipedia fields:
   - Stylistic origins (parent genres)
   - Cultural origins (time period, location)
   - Derivative forms (child genres)
   - Subgenres (variants)
   - Fusion genres (hybrids)
   - Other names (alternative genre names)

2. Extraction challenges:
   - Wikipedia infoboxes often have duplicate column names
   - Solution: Access columns by position not name
     - Column 1 = field names
     - Column 2 = field values
   - Uses regex matching to find field rows (case-insensitive)

3. Quality checks:
   - Identifies "mashed text" problems (e.g., "ChicagohouseTechno")
   - Detects camelCase patterns
   - Flags very long words (20+ characters)

**The Mashed Text Problem:**
Wikipedia's HTML table parser sometimes drops spaces between words:
  - `"Houseelectrosynth-pop"` instead of `"House, electro, synth-pop"`

**Output:**
  - `data/processed/genres_clean.csv`
- Console report showing extraction success rates
- List of problematic genres needing manual fixes

**Typical Results:**
  - 46/66 genres (70%) have stylistic origins
- 14 genres have mashed text requiring fixes

**Runtime:** 5-10 seconds

---
  
  ### 04_fix_mashed_text.R - Manual Text Correction
  
  **Purpose:** Manually corrects Wikipedia entries where spaces were dropped during HTML parsing.

**How it works:**
  1. Developer visits actual Wikipedia pages to find correct text
2. Creates lookup table (tribble) mapping genre → corrected text
3. Left joins corrections with extracted data
4. Updates only problematic entries
5. Re-runs mashed text detection to verify all fixed

**Why Manual Fixing is Necessary:**
  Cannot reliably fix with regex because:
  - "technohouse" could be "techno house" OR "techno, house"
- No way to distinguish compound words from separate genres
- Requires human judgment

**Example Fixes:**
  ```r
tribble(
  ~genre, ~fixed_stylistic_origins,
  "Techno", "House, electro, synth-pop, hi-NRG, EBM, Eurodisco, Italo disco, post-disco",
  "Ambient music", "Background music, beautiful music, drone, dub, easy listening, electronic, experimental, ..."
)
```

**Output:**
  - `data/processed/genres_clean.csv` (updated with corrections)
- Should result in 0 problematic entries

**Runtime:** <1 second

---
  
  ### 05_create_network.R - Network Graph Construction
  
  **Purpose:** Transforms genre relationships into a directed network graph.

**How it works:**
  
  **Step 1: Text Parsing**
  ```r
parse_genre_list(text)
```
Cleans Wikipedia's stylistic origins text:
- Removes citations: `[1]`, `[2]` → deleted
- Removes markup: `[[House music]]` → `House music`
- Removes parentheticals: `House (music)` → `House`
- Normalizes separators: newlines, slashes, "and" → commas
- Splits into individual genre names
- Title case standardization

Example transformation:
```
Input:  "House music\nTechno\nSynth-pop[1] and Electronic"
Output: ["House Music", "Techno", "Synth-Pop", "Electronic"]
```

**Step 2: Edge Creation**
```r
create_edges(genre, origins_text)
```
Creates directed edges (parent → child):

Example:
```
Genre: "Acid House"
Origins: "Chicago house, techno, trance"

Edges created:
  Chicago House → Acid House
  Techno → Acid House
  Trance → Acid House
```

**Step 3: Network Assembly**
1. Processes each genre rowwise
2. Generates all parent-child pairs
3. Removes duplicates
4. Constructs igraph object with `graph_from_data_frame()`

**Output:**
- `data/processed/genre_edges.csv` (edge list: from, to)
- `data/processed/genre_network.rds` (igraph object)

**Statistics Reported:**
- Total nodes (unique genres)
- Total edges (relationships)
- Top 10 most influential parent genres

**Typical Results:**
- 203 nodes (genres)
- 291 edges (relationships)
- Top influencers: Electronic (20), Ambient (9), Musique Concrète (7)

**Runtime:** 2-3 seconds

---

### 06_visualize.R - Network Visualization

**Purpose:** Creates publication-quality visualization of the genre network.

**How it works:**

**Layout Algorithm:** Fruchterman-Reingold ('fr')
- Force-directed layout
- Treats edges as springs, nodes as charged particles
- Iteratively repositions nodes to minimize edge crossings
- Related genres cluster together naturally

**Visual Encoding:**

**Nodes (Genres):**
- Size: Proportional to node degree (total connections)
  - Large nodes = influential genres (many derivatives)
  - Small nodes = niche genres (few connections)
- Color: Steel blue with 80% opacity
- Labels: Genre names, size scaled by degree

**Edges (Relationships):**
- Direction: Arrows show parent → child influence
- Transparency: 20% alpha (reduces visual clutter)
- Color: Gray
- End caps: Prevents arrows overlapping node centers

**Text Labels:**
- Repulsion enabled: Prevents label overlap
- Max overlaps: 30 (balances readability vs completeness)
- Size scaling: Important genres have larger labels

**Export Settings:**
```r
ggsave("output/genre_network.png", width = 20, height = 16, dpi = 300)
```
- Dimensions: 20×16 inches (large format for detail)
- Resolution: 300 DPI (publication quality)
- Format: PNG (lossless, widely compatible)

**Output:**
- `output/genre_network.png` (~2-5 MB file)

**Interpretation:**
- Central hubs: House, Techno, Electronic (many connections)
- Clusters: Related genres group spatially
- Isolated nodes: Genres with unique origins
- Direction flow: Can trace genre evolution paths

**Runtime:** 5-10 seconds

---

## Understanding the Output

### Network Statistics

**Nodes (203 genres):**
- Genres discovered from Wikipedia
- Plus parent genres mentioned in stylistic origins
- Includes genres not in original scrape (e.g., Disco, Funk)

**Edges (291 relationships):**
- Directed: parent → child
- Based on Wikipedia's "Stylistic origins" field
- Represents documented influence

### Top Influential Genres

1. **Electronic (20 derivatives)** - Umbrella term
2. **Ambient (9 derivatives)** - Foundational for downtempo, chillout
3. **Musique Concrète (7)** - Experimental influence
4. **Funk (6)** - Rhythm influence on house, hip-hop genres
5. **Psychedelia (6)** - Psychedelic influence

### Network Clusters Visible

- **House family**: House → Deep House, Tech House, Acid House
- **Ambient cluster**: Ambient → Downtempo, Chillwave, Drone
- **Industrial cluster**: Industrial → Industrial Metal, EBM
- **UK Bass**: UK Garage → Dubstep, Grime, 2-Step

---
  
  ## Customization Options
  
  ### Discover More Genres
  
  Modify `01_discover_genres.R`:
  ```r
main_categories <- c(
  "Electronic_music_genres",
  "Drum_and_bass",           # Add all DnB variants
  "Dubstep",                 # Add dubstep subgenres
  "Ambient_music",           # Add ambient styles
  "Synthwave",               # Add retro electronic
  "Footwork_(genre)"         # Add Chicago footwork
)
```

### Change Visualization Style

Modify `06_visualize.R`:
  
  **Different layouts:**
  ```r
layout = 'kk'        # Kamada-Kawai
layout = 'dh'        # Davidson-Harel
layout = 'graphopt'  # Alternative force-directed
```

**Adjust visual parameters:**
  ```r
width = 30, height = 24     # Larger plot
max.overlaps = 15           # Fewer labels
scale_size_continuous(range = c(2, 8))  # Bigger nodes
```

---
  
  ## Troubleshooting
  
  ### Problem: No genres discovered
  
  **Solutions:**
  1. Check internet connection
2. Verify Wikipedia API accessible: `https://en.wikipedia.org/w/api.php`
3. Try different category names
4. Check if categories exist on Wikipedia

### Problem: All infoboxes empty

**Solutions:**
  1. Wikipedia's infobox HTML structure may have changed
2. Update rvest package: `install.packages("rvest")`
3. Verify CSS selector `.infobox` still correct
4. Check a genre page manually to see structure

### Problem: Too many mashed text entries

**Solutions:**
1. Update `04_fix_mashed_text.R` with new corrections
2. Visit Wikipedia pages to get correct text
3. Add to `fixes` tribble
4. Re-run extraction script

### Problem: Network visualization is cluttered

**Solutions:**
```r
# Reduce label overlaps
max.overlaps = 15  # Lower value = fewer labels

# Filter to major genres only
genre_network_filtered <- induced_subgraph(
  genre_network, 
  V(genre_network)[degree(genre_network) >= 3]
)

# Use different layout
layout = 'kk'  # Kamada-Kawai

# Increase plot size
ggsave(..., width = 30, height = 24)
```

---

## Limitations

### Data Quality

**Wikipedia Dependency:**
- Only genres with Wikipedia pages included
- Relies on editors maintaining infoboxes
- "Stylistic origins" field is subjective

**Missing Genres:**
- Very new genres (not yet documented)
- Regional variants without English Wikipedia pages
- Genres without standardized infoboxes

**Mashed Text:**
- 17 genres required manual correction
- New scrapes may introduce new mashed text

### Network Representation

**Simplifications:**
- Reduces complex musical evolution to parent-child
- Doesn't capture temporal evolution
- All edges weighted equally
- Doesn't show bidirectional influences
- Geographic spread not represented

### Technical Constraints

**Wikipedia Rate Limiting:**
- Script includes delays (0.5-1s per request)
- Very large scrapes (>500 pages) may trigger blocks

**API Limits:**
- Category members limited to 500 results
- Deep category hierarchies not fully explored

---

## Future Enhancements

### Potential Additions

1. **Temporal Analysis:**
   - Extract "Cultural origins" dates
   - Create timeline visualization
   - Show genre evolution over decades

2. **Geographic Mapping:**
   - Parse location information
   - Create world map of genre origins
   - Show regional electronic music scenes

3. **Audio Features:**
   - Integrate with Spotify API
   - Extract BPM, energy, danceability
   - Correlate with genre relationships

4. **Interactive Dashboard:**
   - Shiny app for exploration
   - Filter by decade, region, characteristics
   - Click nodes to see details

5. **Machine Learning:**
   - Predict missing relationships
   - Suggest genre classifications
   - Cluster similar genres

---

## License

MIT License - Feel free to use, modify, and distribute.

---

## Acknowledgments

- **Wikipedia contributors** for maintaining genre infoboxes
- **rvest package** (Hadley Wickham) for web scraping tools
- **igraph package** for network analysis
- **ggraph package** (Thomas Lin Pedersen) for network visualization
- **tidyverse** ecosystem for data manipulation

---

## Version History

**v1.0** (December 2025)
- Initial release
- 7-script automated pipeline
- Discovers, scrapes, and visualizes genre networks
- 203 nodes, 291 edges