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
