get_subfield_name <- function(df) {
  filter(df, i == 1, type == "subfield") %>%
    pull(display_name)
}

safe_get_subfield_name <- purrr::possibly(
  get_subfield_name,
  otherwise = "MISSING-SUBFIELD"
)
