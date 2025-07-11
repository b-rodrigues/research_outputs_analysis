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
    "DE",
    "DK",
    "EE",
    "ES",
    "FI",
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
        country == "DE" ~ "Germany",
        country == "FR" ~ "France",
        country == "LU" ~ "Luxembourg",
        country == "US" ~ "USA",
        country == "CN" ~ "China",
        is.na(country) ~ "Others",
        TRUE ~ "Others"
      )
    ) %>%
    mutate(country_groups = fct_reorder(country_groups, desc(n)))
}


make_plot_coautors_nat <- function(df) {
  country_colors <- c(
    "European Union" = "#003399", # Deep blue (EU flag)
    "Others" = "#FF1493", # Deep pink
    "Luxembourg" = "#FF6B35", # Orange-red
    "France" = "#800080", # Purple
    "USA" = "#228B22", # Forest green
    "Belgium" = "#FFD700", # Gold
    "China" = "#DE2910" # Red
  )

  # Plot for publication with co-authors
  ggplot(df, aes(x = publication_year, y = n, fill = country_groups)) +
    geom_col(position = "dodge", color = "black", size = 0.5) + # Dodge bars for multiple countries per year
    scale_fill_manual(values = country_colors) +
    facet_wrap(
      ~is_lu_first_author,
      labeller = labeller(
        is_lu_first_author = c(
          "FALSE" = "LU Not First Author",
          "TRUE" = "LU First Author"
        )
      )
    ) +
    labs(
      title = "Publications by Country/Region Over Time",
      subtitle = "Faceted by Luxembourg First Author Status",
      x = "Publication Year",
      y = "Total Publications",
      fill = "Country/Region"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 10),
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      strip.text = element_text(face = "bold", size = 11),
      strip.background = element_rect(fill = "lightgray", color = "black")
    ) +
    # Add value labels on top of bars
    geom_text(
      aes(label = n),
      position = position_dodge(width = 0.9),
      vjust = -0.5,
      size = 3,
      fontface = "bold"
    ) +
    # Adjust legend to show in multiple rows if needed
    guides(fill = guide_legend(nrow = 2, byrow = TRUE))
}
