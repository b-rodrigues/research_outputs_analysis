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
    "janitor",
    "jsonlite",
    "lubridate",
    "openalexR",
    "purrr",
    "readr",
    "readxl",
    "tidyr"
  )
)

get_domain_name <- function(df){
  filter(df, i == 1, type == "domain") %>%
    pull(display_name)
}


list(
  tar_target(
    luxembourg_works_path,
    normalizePath("dataset/luxembourg_works.csv")
  ),

  tar_target(
    luxembourg_works_raw,
    read_csv(luxembourg_works_path)
  ),

  tar_target(
    openalex_1,
    luxembourg_works_raw %>%
    mutate(publication_year = year(publication_date)) %>%
    filter(year(publication_date) >= 2015) %>%
    head(10)
  ),

  tar_target(
    openalex_2,
    openalex_1 %>%
    mutate(domain_name = map(topics, get_domain_name))
  )

  
                                        #Need to add the Domain
                                        #luxembourg_works %>% head(1)  %>% pull(topics) %>% .[[1]] %>%   filter(i == 1, type == "domain") %>% pull(display_name) 

  tar_target(
    authorships_topics_df,
    select(
      openalex_1,
      publication_year, topics, authorships
    ) %>%
    unnest(authorships, names_sep = "_") %>%
    select(publication_year, topics, authorships_affiliations) %>%
    unnest(authorships_affiliations) %>%
    count(publication_year, topics, country_code)
    
  ),

  tar_target(
    authors_countries,
    openalex_2 %>%
      select(publication_year, authors_countries) %>%
      group_by(publication_year) %>%
      reframe(authors_countries = unlist(authors_countries)) %>%
      count(publication_year, authors_countries)
  )

)
