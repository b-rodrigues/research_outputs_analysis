# =============================================================================
# TARGETS PIPELINE CONFIGURATION
# =============================================================================
# Purpose: Data processing pipeline for Luxembourg research publications
# =============================================================================

library(targets)
library(tarchetypes)

# Package configuration
tar_option_set(
  packages = c(
    "archive",
    "data.table",
    "dplyr",
    "ggplot2",
    "httr",
    "jsonlite",
    "lubridate",
    "openalexR",
    "purrr",
    "readr",
    "readxl",
    "tidyr"
  )
)

parse_single_quote_json_list <- function(json_list) {
  
  # Helper function to parse a single JSON string
  parse_single_json <- function(json_string) {
    
    # Handle NULL or empty strings
    if (is.null(json_string) || is.na(json_string) || nchar(trimws(json_string)) == 0) {
      return(data.frame(error = "empty_or_null", stringsAsFactors = FALSE))
    }
    
    tryCatch({
      # Remove outer braces
      content <- gsub("^\\{\\s*|\\s*\\}$", "", json_string)
      
      # Initialize result list
      result <- list()
      
      # First, handle the lineage array separately since it's complex
      lineage_pattern <- "'lineage':\\s*\\[(.*?)\\]"
      lineage_match <- regexpr(lineage_pattern, content, perl = TRUE)
      
      if (lineage_match > 0) {
        # Extract the lineage array
        lineage_full <- regmatches(content, lineage_match)
        lineage_content <- gsub("'lineage':\\s*\\[|\\]", "", lineage_full)
        
        # Split by comma and clean single quotes
        if (nchar(trimws(lineage_content)) > 0) {
          lineage_items <- strsplit(lineage_content, ",\\s*")[[1]]
          lineage_values <- gsub("^'|'$", "", trimws(lineage_items))
          result$lineage <- list(lineage_values)
        } else {
          result$lineage <- list(character(0))
        }
        
        # Remove lineage from content
        content <- gsub(lineage_pattern, "", content, perl = TRUE)
      }
      
      # Clean up any trailing commas
      content <- gsub(",\\s*$", "", content)
      content <- gsub("^,\\s*", "", content)  # Also remove leading commas
      
      # Now handle the remaining simple key-value pairs
      if (nchar(trimws(content)) > 0) {
        # Split by comma
        pairs <- strsplit(content, ",\\s*(?=')", perl = TRUE)[[1]]
        
        for (pair in pairs) {
          pair <- trimws(pair)
          if (nchar(pair) > 0 && grepl(":", pair)) {
            # Split on the first colon
            parts <- strsplit(pair, ":", 2)[[1]]
            if (length(parts) == 2) {
              key <- trimws(gsub("^'|'$", "", trimws(parts[1])))
              value <- trimws(gsub("^'|'$", "", trimws(parts[2])))
              
              if (nchar(key) > 0) {
                result[[key]] <- value
              }
            }
          }
        }
      }
      
      # Convert to data frame - FIXED: proper initialization
      if (length(result) == 0) {
        # Return empty data frame with at least one column if no data parsed
        return(data.frame(empty_result = TRUE, stringsAsFactors = FALSE))
      }
      
      # Create data frame with proper row initialization
      df <- data.frame(stringsAsFactors = FALSE)
      
      # Add each field one by one
      for (name in names(result)) {
        if (is.list(result[[name]]) && !is.data.frame(result[[name]])) {
          # Handle list columns (like lineage) - use I() to preserve list structure
          if (nrow(df) == 0) {
            df <- data.frame(row.names = 1, stringsAsFactors = FALSE)
          }
          df[[name]] <- I(result[[name]])
        } else {
          # Regular columns
          if (nrow(df) == 0) {
            df <- data.frame(row.names = 1, stringsAsFactors = FALSE)
          }
          df[[name]] <- result[[name]]
        }
      }
      
      return(df)
      
    }, error = function(e) {
      return(data.frame(error = paste("parse_error:", e$message), stringsAsFactors = FALSE))
    })
  }
  
  # Apply to each element in the list and combine
  parsed_list <- lapply(json_list, parse_single_json)
  
  # Combine all data frames, handling different column structures
  tryCatch({
    # Use dplyr::bind_rows to handle different column structures gracefully
    if (requireNamespace("dplyr", quietly = TRUE)) {
      combined_df <- dplyr::bind_rows(parsed_list)
    } else {
      # Fallback: use rbind.fill if available, otherwise basic rbind
      if (requireNamespace("plyr", quietly = TRUE)) {
        combined_df <- plyr::rbind.fill(parsed_list)
      } else {
        # Basic approach - might fail if columns don't match
        combined_df <- do.call(rbind, parsed_list)
      }
    }
    rownames(combined_df) <- NULL
    return(combined_df)
  }, error = function(e) {
    # If combining fails, return the list of individual data frames
    warning("Could not combine data frames, returning list: ", e$message)
    return(parsed_list)
  })
}

list(
  tar_target(
    openalex_raw,
    archive_read(
      normalizePath("dataset/luxembourg-openalex-manual-query.7z"),
      file = "luxembourg-openalex-manual-query.csv"
    ) |>
    read_csv()
  ),

  tar_target(
    openalex_1,
    filter(openalex_raw, publication_year >= 2015) %>%
    head(10)
  ),

  tar_target(
    openalex_2,
    mutate(
      openalex_1,
      authors_countries = strsplit(`authorships.countries`, "\\|"),
      institutions = strsplit(`authorships.institutions`, "\\|"),
      institutions = map(institutions, parse_single_quote_json_list)
    )

  )

)
