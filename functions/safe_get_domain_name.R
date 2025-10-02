safe_get_domain_name <- purrr::possibly(
  get_domain_name,
  otherwise = "MISSING-DOMAIN"
)
