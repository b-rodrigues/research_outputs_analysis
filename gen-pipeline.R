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
    name = dataset,
    expr = filter(
      openalex_1,
      type == "article"
    ) %>%
      mutate(
        first_author_country = map(authorships, get_first_author_country),
        all_authors_countries = map(authorships, get_all_authors_country),
        is_lu_first_author = map_lgl(first_author_country, \(x) {
          (grepl("LU", x))
        }),
        primary_domain_name = map_chr(topics, safe_get_domain_name),
        primary_subfield_name = map_chr(topics, safe_get_subfield_name)
      ),
    additional_files = "functions.R"
  ),

  # Summarize the count of articles by publication year and LU-first-author status.
  rxp_r(
    name = lu_first_authors,
    expr = dataset %>%
      group_by(publication_year, is_lu_first_author) %>%
      summarise(total = n_distinct(doi), .groups = 'drop')
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
    name = primary_subfield_lu,
    expr = tabyl(
      dataset,
      primary_subfield_name,
      is_lu_first_author
    )
  ),

  # Country affiliations of co-authors per is_lu_first_author
  rxp_r(
    name = country_authors_1,
    expr = {
      dataset %>%
        select(publication_year, is_lu_first_author, all_authors_countries) %>%
        unnest(cols = c(all_authors_countries)) %>%
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
    name = country_authors,
    expr = country_authors_1 %>%
      group_by(publication_year, is_lu_first_author, country) %>%
      summarise(countries = sum(n), .groups = "drop")
  ),

  # Render the final Quarto report.
  rxp_qmd(
    name = report,
    qmd_file = "report/report.qmd"
  )
) |>
  rixpress(project_path = ".", build = TRUE)

# After running, you can visualize the pipeline's Directed Acyclic Graph (DAG) with:
# rxp_ggdag()
