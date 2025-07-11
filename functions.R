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

get_all_authors_country <- function(df) {
  df %>%
    pull(affiliations) %>%
    map(bind_rows) %>%
    map(\(x) (pull(x, country_code))) %>%
    unlist() %>%
    tabyl()
}
