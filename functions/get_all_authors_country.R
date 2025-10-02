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
