library(openalexR)
library(readr)

# Get the data from Luxembourg
luxembourg_works <- oa_fetch(
  entity = "works",
  # Filter for works with at least one author affiliated with Luxembourg
  authorships.institutions.country_code = "LU",
  # Select the fields you requested
  options = list(select = c(
    "id",
    "doi",
    "title",
    "publication_date",
    "type",
    "primary_topic",
    "topics", # The first item in this list is the primary topic
    "keywords",
    "sustainable_development_goals",
    "language",
    "primary_location",
    "cited_by_count",
    "counts_by_year",
    "open_access",
    "authorships"
  )),
  # Set a reasonable limit (adjust as needed)
  count_only = FALSE,
  verbose = TRUE
)

# Need to save as RDS because of list columns of dfs
saveRDS(luxembourg_works, "dataset/luxembourg_works.rds")
