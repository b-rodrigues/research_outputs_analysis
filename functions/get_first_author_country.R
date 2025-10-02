get_first_author_country <- function(df) {
  filter(df, author_position == "first") %>%
    pull(affiliations) %>%
    map(bind_rows) %>%
    map(\(x) (pull(x, country_code)))
}
