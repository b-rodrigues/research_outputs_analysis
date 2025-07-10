# This script uses the {rix} package to generate a 'default.nix' file,
# which defines a reproducible environment for the pipeline.

library(rix)

# Define the execution environment for the pipeline.
# This includes all necessary R packages, Quarto for rendering,
# and pulls a pinned version of {rixpress} from GitHub.
rix(
  date = "2025-07-07",
  r_pkgs = c(
    "R_utils",
    "archive",
    "crosstalk",
    "dplyr",
    "DT",
    "ggplot2",
    "httr",
    "htmltools",
    "janitor",
    "jsonlite",
    "lubridate",
    "openalexR",
    "plotly",
    "purrr",
    "quarto",
    "readr",
    "readxl",
    "rix",
    "tarchetypes",
    "targets",
    "tidyjson",
    "tidyr",
    "tinytable",
    "xml2"
  ),
  git_pkgs = list(
    list(
      package_name = "rixpress",
      repo_url = "https://github.com/b-rodrigues/rixpress",
      commit = "dfef00af24b43aabbcf26efe61b3fb72d4a89bd9"
    )
  ),
  system_pkgs = c(
    "air-formatter",
    "quarto",
    "typst",
    "which"
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
