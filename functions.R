get_domain_name <- function(df) {
  filter(df, i == 1, type == "domain") %>%
    pull(display_name)
}

safe_get_domain_name <- purrr::possibly(
  get_domain_name,
  otherwise = "MISSING-DOMAIN"
)

get_subfield_name <- function(df) {
  filter(df, i == 1, type == "subfield") %>%
    pull(display_name)
}

safe_get_subfield_name <- purrr::possibly(
  get_subfield_name,
  otherwise = "MISSING-SUBFIELD"
)

get_first_author_country <- function(df) {
  filter(df, author_position == "first") %>%
    pull(affiliations) %>%
    map(bind_rows) %>%
    map(\(x) (pull(x, country_code)))
}

get_all_authors_country <- function(df, distribution = FALSE) {
  count_f <- if (!distribution) {
    unique
  } else {
    tabyl
  }
  df %>%
    pull(affiliations) %>%
    map(bind_rows) %>%
    map(\(x) (pull(x, country_code))) %>%
    unlist() %>%
    count_f()
}

get_country_groups <- function(df) {
  eu_countries <- c(
    "AT",
    "BG",
    "CY",
    "CZ",
    "DK",
    "EE",
    "ES",
    "FI",
    "GB",
    "HR",
    "HU",
    "IE",
    "IT",
    "LT",
    "LV",
    "MT",
    "NL",
    "PL",
    "PT",
    "RO",
    "SE",
    "SI",
    "SK"
  )

  df %>%
    mutate(
      country_groups = case_when(
        country %in% eu_countries ~ "European Union",
        country == "BE" ~ "Belgium",
        country == "CH" ~ "Switzerland",
        country == "CN" ~ "China",
        country == "DE" ~ "Germany",
        country == "FR" ~ "France",
        country == "LU" ~ "Luxembourg",
        country == "US" ~ "USA",
        is.na(country) ~ "Others",
        TRUE ~ "Others"
      )
    )
}
