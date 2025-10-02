get_domain_name <- function(df) {
  filter(df, i == 1, type == "domain") %>%
    pull(display_name)
}
