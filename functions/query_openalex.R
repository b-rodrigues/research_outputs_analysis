# Luxembourg Research Data Extraction Script - Simplified
# Extract raw Luxembourg research data from OpenAlex
# Date: 2025-06-30
# User: b-rodrigues

# Load required libraries
library(openalexR)
library(dplyr)
library(purrr)
library(readr)
library(httr)

# Configuration
API_DELAY <- 1.0
MAX_RETRIES <- 3
TIMEOUT_SECONDS <- 60
OUTPUT_DIR <- "data"
START_YEAR <- 1970
CURRENT_YEAR <- 2025

# Create output directory
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Polite API wrapper with comprehensive error handling
safe_oa_fetch <- function(..., max_retries = MAX_RETRIES, base_delay = API_DELAY) {
  
  args <- list(...)
  attempt <- 1
  
  while (attempt <= max_retries) {
    
    cat(sprintf("API request attempt %d/%d\n", attempt, max_retries))
    
    # Calculate delay with exponential backoff
    if (attempt > 1) {
      delay <- base_delay * (2 ^ (attempt - 2))
      cat(sprintf("Waiting %.1f seconds before retry...\n", delay))
      Sys.sleep(delay)
    } else {
      # Always be polite, even on first attempt
      Sys.sleep(base_delay)
    }
    
    result <- tryCatch({
      do.call(oa_fetch, args)
    }, error = function(e) {
      cat("Error on attempt", attempt, ":", e$message, "\n")
      
      # Check error type
      if (grepl("429", e$message)) {
        cat("Rate limit hit, will retry with longer delay\n")
      } else if (grepl("50[0-9]", e$message)) {
        cat("Server error, will retry\n")
      } else if (grepl("timeout|connection", e$message, ignore.case = TRUE)) {
        cat("Connection issue, will retry\n")
      } else {
        cat("Unknown error type\n")
      }
      
      NULL
    })
    
    # Success
    if (!is.null(result)) {
      if (args$count_only %||% FALSE) {
        cat("Count query successful:", result, "\n")
      } else {
        cat("Data query successful:", nrow(result), "records\n")
      }
      return(result)
    }
    
    attempt <- attempt + 1
  }
  
  # All attempts failed
  cat("All retry attempts failed, returning empty result\n")
  if (args$count_only %||% FALSE) {
    return(0)
  } else {
    return(tibble())
  }
}

# =============================================================================
# STEP 1: FIND LUXEMBOURG INSTITUTIONS (SIMPLIFIED)
# =============================================================================

cat("=== STEP 1: SEARCHING FOR LUXEMBOURG INSTITUTIONS ===\n")

luxembourg_institutions <- tibble()

# 1. Broad country search (captures most institutions)
cat("1. Broad Luxembourg country search...\n")
broad_institutions <- safe_oa_fetch(
  entity = "institutions",
  country_code = "lu",
  count_only = FALSE,
  verbose = TRUE
)

if (nrow(broad_institutions) > 0) {
  luxembourg_institutions <- broad_institutions %>%
    mutate(search_method = "country_code")
  cat(sprintf("Found %d institutions via country code\n", nrow(broad_institutions)))
}

# 2. Search for major institutions that might be missed
major_institutions <- c(
  "University of Luxembourg",
  "Luxembourg Institute of Science and Technology", 
  "LIST",
  "Luxembourg Institute for Socio-Economic Research",
  "LISER", 
  "Luxembourg Institute of Health",
  "LIH",
  "Centre de Recherche Public Henri Tudor",
  "CRP Henri Tudor",
  "CEPS/INSTEAD",
  "Centre de Recherche Public Gabriel Lippmann"
)

cat("2. Searching for major institutions by name...\n")
for (i in seq_along(major_institutions)) {
  inst_name <- major_institutions[i]
  cat(sprintf("[%d/%d] Searching: %s\n", i, length(major_institutions), inst_name))
  
  result <- safe_oa_fetch(
    entity = "institutions",
    display_name.search = paste0('"', inst_name, '"'),
    count_only = FALSE,
    verbose = FALSE
  )
  
  if (nrow(result) > 0) {
    cat("  → Found\n")
    result <- result %>% mutate(search_method = "major_institution_search")
    luxembourg_institutions <- bind_rows(luxembourg_institutions, result)
  }
}

# 3. Final deduplication
luxembourg_institutions <- luxembourg_institutions %>%
  distinct(id, .keep_all = TRUE) %>%
  arrange(display_name)

cat(sprintf("Final count: %d unique Luxembourg institutions\n", nrow(luxembourg_institutions)))

# Show what we found
cat("\nInstitutions found:\n")
print(luxembourg_institutions %>% select(display_name, country_code, search_method))

# =============================================================================
# STEP 2: FIND FNR FUNDER
# =============================================================================

cat("\n=== STEP 2: SEARCHING FOR FNR FUNDER ===\n")

fnr_variants <- c(
  "Fonds National de la Recherche Luxembourg",
  "Luxembourg National Research Fund",
  "FNR Luxembourg",
  "National Research Fund Luxembourg"
)

fnr_results <- tibble()

for (i in seq_along(fnr_variants)) {
  variant <- fnr_variants[i]
  cat(sprintf("[%d/%d] Searching for: %s\n", i, length(fnr_variants), variant))
  
  result <- safe_oa_fetch(
    entity = "funders",
    display_name.search = paste0('"', variant, '"'),
    count_only = FALSE,
    verbose = FALSE
  )
  
  if (nrow(result) > 0) {
    cat("  → Found match\n")
    fnr_results <- bind_rows(fnr_results, 
                           result %>% mutate(search_term = variant))
  } else {
    cat("  → No match\n")
  }
}

if (nrow(fnr_results) > 0) {
  # Take the best match (first one found)
  fnr_funder <- fnr_results %>%
    distinct(id, .keep_all = TRUE) %>%
    slice(1)
  
  cat(sprintf("FNR found: %s (ID: %s)\n", fnr_funder$display_name, fnr_funder$id))
} else {
  cat("No FNR funder found\n")
  fnr_funder <- tibble(id = NA_character_, display_name = "FNR Not Found")
}

# =============================================================================
# STEP 3: FETCH ALL WORKS IN 5-YEAR CHUNKS
# =============================================================================

cat("\n=== STEP 3: FETCHING LUXEMBOURG WORKS IN 5-YEAR CHUNKS ===\n")

# Create 5-year chunks
year_chunks <- seq(START_YEAR, CURRENT_YEAR, by = 5)
institution_ids <- luxembourg_institutions$id[!is.na(luxembourg_institutions$id)]

all_works <- tibble()

for (start_year in year_chunks) {
  end_year <- min(start_year + 4, CURRENT_YEAR)
  
  cat(sprintf("\n=== PROCESSING YEARS %d-%d ===\n", start_year, end_year))
  
  chunk_works <- tibble()
  
  # Fetch works by institutions for this year range
  if (length(institution_ids) > 0) {
    
    cat(sprintf("--- Fetching by institutions (%d-%d) ---\n", start_year, end_year))
    
    works_inst <- safe_oa_fetch(
      entity = "works",
      institutions.id = institution_ids,
      publication_year = paste(start_year, end_year, sep = "-"),
      output = "tibble",
      verbose = TRUE
    )
    
    if (nrow(works_inst) > 0) {
      works_inst <- works_inst %>% 
        mutate(
          source = "institutions",
          year_chunk = paste(start_year, end_year, sep = "-")
        )
      chunk_works <- bind_rows(chunk_works, works_inst)
      cat(sprintf("Retrieved %s works by institutions (%d-%d)\n", 
                  format(nrow(works_inst), big.mark = ","), start_year, end_year))
    }
  }
  
  # Fetch works by FNR funding for this year range
  if (!is.na(fnr_funder$id)) {
    
    cat(sprintf("--- Fetching by FNR funding (%d-%d) ---\n", start_year, end_year))
    
    works_fnr <- safe_oa_fetch(
      entity = "works",
      grants.funder = fnr_funder$id,
      publication_year = paste(start_year, end_year, sep = "-"),
      output = "tibble",
      verbose = TRUE
    )
    
    if (nrow(works_fnr) > 0) {
      works_fnr <- works_fnr %>% 
        mutate(
          source = "fnr_funding",
          year_chunk = paste(start_year, end_year, sep = "-")
        )
      chunk_works <- bind_rows(chunk_works, works_fnr)
      cat(sprintf("Retrieved %s works by FNR funding (%d-%d)\n", 
                  format(nrow(works_fnr), big.mark = ","), start_year, end_year))
    }
  }
  
  # Add chunk to overall collection (no deduplication yet)
  if (nrow(chunk_works) > 0) {
    all_works <- bind_rows(all_works, chunk_works)
    cat(sprintf("Total works so far: %s\n", format(nrow(all_works), big.mark = ",")))
  } else {
    cat(sprintf("No works retrieved for %d-%d\n", start_year, end_year))
  }
}

# Final deduplication across all chunks
cat("\n=== FINAL DEDUPLICATION ===\n")
cat(sprintf("Total records before deduplication: %s\n", format(nrow(all_works), big.mark = ",")))

final_works_raw <- all_works %>%
  distinct(id, .keep_all = TRUE)

cat(sprintf("Final unique records: %s\n", format(nrow(final_works_raw), big.mark = ",")))

# =============================================================================
# STEP 4: EXPORT RAW DATA
# =============================================================================

cat("\n=== STEP 4: EXPORTING RAW DATA ===\n")

if (nrow(final_works_raw) == 0) {
  cat("No works to export\n")
  stop("No data retrieved - check API connections and institution/funder IDs")
}

# Generate filename with timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
csv_filename <- sprintf("luxembourg-openalex-api-query.csv")

# Export raw CSV
write_csv(final_works_raw, file.path(OUTPUT_DIR, csv_filename), na = "")

cat(sprintf("Exported %s raw works to %s\n", format(nrow(final_works_raw), big.mark = ","), csv_filename))
cat(sprintf("File size: %.2f MB\n", file.size(file.path(OUTPUT_DIR, csv_filename)) / 1024^2))

# Show basic summary
cat("\nBasic summary:\n")
cat(sprintf("Total works: %s\n", format(nrow(final_works_raw), big.mark = ",")))
cat(sprintf("Year range: %d - %d\n", 
            min(final_works_raw$publication_year, na.rm = TRUE),
            max(final_works_raw$publication_year, na.rm = TRUE)))
cat(sprintf("Sources: %s\n", paste(unique(final_works_raw$source), collapse = ", ")))

cat(sprintf("\n=== EXTRACTION COMPLETE ===\n"))
cat(sprintf("Raw data saved to: %s/%s\n", OUTPUT_DIR, csv_filename))
