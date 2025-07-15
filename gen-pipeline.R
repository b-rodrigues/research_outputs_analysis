library(rixpress)

list(
  rxp_r_file(
    name = luxembourg_works_raw,
    path = "dataset/luxembourg_works.rds",
    read_function = readRDS
  ),

  rxp_r(
    name = openalex_1,
    expr = luxembourg_works_raw %>%
      mutate(
        publication_year = year(publication_date),
        doi_missing = is.na(doi)
      ) %>%
      filter(
        publication_year >= 2015
      )
  ),

  rxp_r(
    name = type_doi_missing,
    expr = openalex_1 %>%
      mutate(
        doi_missing = ifelse(
          doi_missing,
          "Has_DOI",
          "DOI_missing"
        )
      ) %>%
      tabyl(type, doi_missing) %>%
      mutate(Total = Has_DOI + DOI_missing) %>%
      rename(
        Type = type
      )
  ),

  rxp_r(
    name = openalex_articles,
    expr = filter(
      openalex_1,
      type == "article"
    )
  ),

  rxp_r(
    name = dataset_first_author_country,
    expr = openalex_articles %>%
      mutate(
        first_author_country = map(authorships, get_first_author_country),
        is_lu_first_author = map_lgl(first_author_country, \(x) {
          (grepl("LU", x))
        })
      ),
    additional_files = "functions.R"
  ),

  rxp_r(
    name = dataset_all_authors_countries_distribution,
    expr = openalex_articles %>%
      mutate(
        all_authors_countries_distribution = map(
          authorships,
          get_all_authors_country,
          distribution = TRUE
        )
      ),
    additional_files = "functions.R"
  ),

  rxp_r(
    name = dataset_all_authors_countries_unique,
    expr = openalex_articles %>%
      mutate(
        all_authors_countries_unique = map(
          authorships,
          get_all_authors_country,
          distribution = FALSE
        )
      ),
    additional_files = "functions.R"
  ),

  rxp_r(
    name = dataset_primary_domain_name,
    expr = openalex_articles %>%
      mutate(
        primary_domain_name = map_chr(topics, safe_get_domain_name),
        primary_subfield_name = map_chr(topics, safe_get_subfield_name)
      ),
    additional_files = "functions.R"
  ),

  rxp_r(
    name = dataset_primary_subfield_name,
    expr = openalex_articles %>%
      mutate(
        primary_subfield_name = map_chr(topics, safe_get_subfield_name)
      ),
    additional_files = "functions.R"
  ),

  rxp_r(
    name = dataset,
    expr = {
      bind_cols(
        openalex_articles,
        select(
          dataset_first_author_country,
          first_author_country,
          is_lu_first_author
        ),
        select(
          dataset_all_authors_countries_distribution,
          all_authors_countries_distribution
        ),
        select(
          dataset_all_authors_countries_unique,
          all_authors_countries_unique
        ),
        select(
          dataset_primary_domain_name,
          primary_domain_name,
          primary_subfield_name
        )
      )
    }
  ),

  # Summarize the count of articles by publication year and LU-first-author status.
  rxp_r(
    name = lu_first_authors,
    expr = dataset %>%
      group_by(publication_year, is_lu_first_author) %>%
      summarise(total = n_distinct(doi), .groups = 'drop')
  ),

  # Summarize the count of articles by publication year and LU-first-author status.
  rxp_r(
    name = languages,
    expr = dataset %>%
      mutate(
        is_en = if_else(
          language == "en",
          "English",
          "Other language",
          "Missing language"
        )
      ) %>%
      mutate(
        is_lu_first_author = if_else(
          is_lu_first_author,
          "LU",
          "Non-LU",
          NA_character_
        )
      ) %>%
      group_by(
        publication_year,
        is_lu_first_author,
        primary_domain_name,
        is_en
      ) %>%
      summarise(total = n_distinct(doi), .groups = 'drop') %>%
      pivot_wider(names_from = "is_en", values_from = "total") %>%
      arrange(desc(publication_year))
  ),

  # Summarize by primary domain and LU-affiliated first authors.
  rxp_r(
    name = primary_domain_lu,
    expr = dataset %>%
      group_by(publication_year, primary_domain_name, is_lu_first_author) %>%
      summarise(total = n_distinct(doi), .groups = 'drop')
  ),

  # Create a table of primary subfields by LU-affiliated first-author status.
  rxp_r(
    name = primary_subfield_lu_raw,
    expr = dataset %>%
      group_by(publication_year, primary_subfield_name, is_lu_first_author) %>%
      summarise(total = n_distinct(doi), .groups = 'drop') %>%
      arrange(desc(total))
  ),

  rxp_r(
    name = top_lu_subfields,
    expr = primary_subfield_lu_raw %>%
      filter(
        is_lu_first_author,
        publication_year == 2024
      ) %>%
      arrange(desc(total)) %>%
      head(10) %>%
      pull(primary_subfield_name)
  ),

  rxp_r(
    name = top_non_lu_subfields,
    expr = primary_subfield_lu_raw %>%
      filter(
        !is_lu_first_author,
        publication_year == 2024
      ) %>%
      arrange(desc(total)) %>%
      head(10) %>%
      pull(primary_subfield_name)
  ),

  rxp_r(
    name = top_subfields,
    expr = unique(c(top_lu_subfields, top_non_lu_subfields))
  ),

  rxp_r(
    name = primary_subfield_lu,
    expr = primary_subfield_lu_raw %>%
      filter(primary_subfield_name %in% top_subfields) %>%
      arrange(desc(publication_year))
  ),

  # Country affiliations of co-authors per is_lu_first_author
  rxp_r(
    name = country_authors_1,
    expr = {
      dataset %>%
        select(
          publication_year,
          is_lu_first_author,
          all_authors_countries_distribution
        ) %>%
        unnest(cols = c(all_authors_countries_distribution)) %>%
        setNames(c(
          'publication_year',
          'is_lu_first_author',
          'country',
          'n',
          'p',
          'vp'
        ))
    }
  ),

  rxp_r(
    name = country_authors_distribution,
    expr = country_authors_1 %>%
      get_country_groups() %>%
      group_by(publication_year, is_lu_first_author, country_groups) %>%
      summarise(total = sum(n), .groups = "drop")
  ),

  rxp_r(
    name = country_authors_unique,
    expr = dataset %>%
      select(
        publication_year,
        is_lu_first_author,
        all_authors_countries_unique
      ) %>%
      unnest(cols = c("all_authors_countries_unique")) %>%
      filter(!(is_lu_first_author & all_authors_countries_unique == "LU")) %>%
      rename(country = all_authors_countries_unique) %>%
      group_by(
        publication_year,
        is_lu_first_author,
        country
      ) %>%
      summarise(n = n(), .groups = "drop") %>%
      get_country_groups() %>%
      group_by(
        publication_year,
        is_lu_first_author,
        country_groups
      ) %>%
      summarise(n = sum(n), .groups = "drop") %>%
      mutate(country_groups = fct_reorder(country_groups, desc(n)))
  ),

  rxp_r(
    name = citation_data,
    expr = dataset %>%
      select(
        publication_year,
        doi,
        is_lu_first_author,
        primary_domain_name,
        cited_by_count
      )
  ),

  # Render the final Quarto report.
  rxp_qmd(
    name = report,
    qmd_file = "report/report.qmd"
  )
) |>
  rixpress(project_path = ".", build = FALSE)

rxp_make(max_jobs = 4, cores = 1)

# After running, you can visualize the pipeline's Directed Acyclic Graph (DAG) with:
# rxp_ggdag()
