library(openalexR)
library(readr)

fetch_works <- function(country_code = NULL, institution_ids = NULL, save_path = NULL) {
  if (is.null(country_code) && is.null(institution_ids)) {
    stop("You must provide either a country_code or institution_ids.")
  }
  if (!is.null(country_code) && !is.null(institution_ids)) {
    stop("Please provide only one of country_code or institution_ids, not both.")
  }

  # Build the filter
  filter_args <- list()
  if (!is.null(country_code)) {
    filter_args$authorships.institutions.country_code <- country_code
  }
  if (!is.null(institution_ids)) {
    filter_args$authorships.institutions.id <- institution_ids
  }

  # Fetch
  works <- do.call(
    oa_fetch,
    c(
      list(
        entity = "works",
        options = list(
          select = c(
            "id",
            "doi",
            "title",
            "publication_date",
            "type",
            "primary_topic",
            "topics",
            "keywords",
            "sustainable_development_goals",
            "language",
            "primary_location",
            "cited_by_count",
            "citation_normalized_percentile",
            "counts_by_year",
            "open_access",
            "authorships"
          )
        ),
        count_only = FALSE,
        verbose = TRUE
      ),
      filter_args
    )
  )

  # Optionally save
  if (!is.null(save_path)) {
    saveRDS(works, save_path)
  }

  return(works)
}

luxembourg_works <- fetch_works(
  country_code = "LU",
  save_path = paste0("dataset/luxembourg_works_", Sys.Date(), ".rds")
)

harvard_works <- fetch_works(
  institution_ids = "https://openalex.org/I136199984",
  save_path = paste0("dataset/harvard_works_", Sys.Date(), ".rds")
)
