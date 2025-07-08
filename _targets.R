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

get_subfield_name <- function(df){
  filter(df, i == 1, type == "subfield") %>%
    pull(display_name)
}

safe_get_domain_name <- purrr::possibly(get_domain_name, otherwise = "MISSING-DOMAIN")
safe_get_subfield_name <- purrr::possibly(get_subfield_name, otherwise = "MISSING-SUBFIELD")

get_first_author_country <- function(df){
  filter(df, author_position == "first") %>%
    pull(affiliations) %>%
    map(bind_rows) %>%
    map(\(x)(pull(x, country_code)))
}


list(
  tar_target(
    luxembourg_works_path,
    normalizePath("dataset/luxembourg_works.rds")
  ),

  tar_target(
    luxembourg_works_raw,
    readRDS(luxembourg_works_path)
  ),

  tar_target(
    openalex_1,
    luxembourg_works_raw %>%
    mutate(
      publication_year = year(publication_date),
      doi_missing = is.na(doi)
    ) %>%
    filter(
      year(publication_date) >= 2015
    )
  ),

  tar_target(
    type_doi_missing,
    tabyl(openalex_1, type, doi_missing) %>%
    mutate(Total = `FALSE`+`TRUE`) %>%
    rename(
      Type = type,
      `Has DOI` = `FALSE`,
      `DOI missing` = `TRUE`
    )
  ),

  tar_target(
    dataset,
    filter(
      openalex_1,
      type == "article"
    ) %>%
    mutate(
      first_author_country = map(authorships, get_first_author_country),
      is_lu_first_author = map_lgl(first_author_country, \(x)(grepl("LU", x))),
      primary_domain_name = map_chr(topics, safe_get_domain_name),
      primary_subfield_name = map_chr(topics, safe_get_subfield_name)
    )
  ),

  tar_target(
    lu_first_authors,
    dataset %>%
    group_by(publication_year, is_lu_first_author) %>%
    summarise(total = n_distinct(doi))
  ),

  tar_target(
    primary_domain_lu,
    dataset %>%
    group_by(publication_year, primary_domain_name, is_lu_first_author) %>%
    summarise(total = n_distinct(doi)) 
    #rename(
    #  `Primary domain name` = primary_domain_name,
    #  `Not LU-affiliated first author` = `FALSE`,
    #  `LU-affiliated first author` = `TRUE`
    #)
  ),

  tar_target(
    primary_subfield_lu,
    tabyl(
      dataset,
      primary_subfield_name,
      is_lu_first_author
    )
  ),

  tar_quarto(
    report,
    path = "report/report.qmd"
  )

                                        #tar_target(
                                        #  openalex_2,
                                        #  openalex_1 %>%
                                        #  mutate(domain_name = map(topics, get_domain_name))
                                        #)

  #
  #                                      #Need to add the Domain
  #                                      #luxembourg_works %>% head(1)  %>% pull(topics) %>% .[[1]] %>%   filter(i == 1, type == "domain") %>% pull(display_name) 

  #tar_target(
  #  authorships_topics_df,
  #  select(
  #    openalex_1,
  #    publication_year, topics, authorships
  #  ) %>%
  #  unnest(authorships, names_sep = "_") %>%
  #  select(publication_year, topics, authorships_affiliations) %>%
  #  unnest(authorships_affiliations) %>%
  #  count(publication_year, topics, country_code)
  #  
  #),

  #tar_target(
  #  authors_countries,
  #  openalex_2 %>%
  #    select(publication_year, authors_countries) %>%
  #    group_by(publication_year) %>%
  #    reframe(authors_countries = unlist(authors_countries)) %>%
  #    count(publication_year, authors_countries)
  #)

)
