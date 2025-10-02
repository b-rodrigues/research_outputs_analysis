get_domain_name <- function(df) {
  filter(df, i == 1, type == "domain") %>%
    pull(display_name)
}

safe_get_domain_name <- purrr::possibly(
  get_domain_name,
  otherwise = "MISSING-DOMAIN"
)
