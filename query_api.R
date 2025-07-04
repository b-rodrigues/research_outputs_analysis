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
    "topics", # The first item in this list is the primary topic
    "keywords",
    "sustainable_development_goals",
    "language",
    "open_access",
    "authorships"
  )),
  # Set a reasonable limit (adjust as needed)
  count_only = FALSE,
  verbose = TRUE
)

write_csv(luxembourg_works, "dataset/luxembourg_works.csv")
