validate_tenant_id <- function(x) {
  if (!rlang::is_string(x)) {
    cli::cli_abort("input must be a character vector")
  }

  for (y in x) {
    if (!grepl("^[A-Za-z0-9.-]+$", y)) {
      cli::cli_abort("tenant id {.val {y}} is not valid")
    }
  }
  TRUE
}


validate_scope <- function(x) {
  if (!rlang::is_string(x)) {
    cli::cli_abort("input must be a character vector")
  }

  for (y in x) {
    if (!grepl("^[A-Za-z0-9_.:/-]+$", y)) {
      cli::cli_abort("scope {.val {x}} is not valid")
    }
  }
  TRUE
}


get_scope_resource <- function(scope) {
  x <- grep("^http", scope, value = TRUE, ignore.case = TRUE)

  if(length(x) != 1L)
    cli::cli_abort("invalid scope {.val {scope}}")

  u <- httr2::url_parse(x)
  u$path <- NULL
  u$query <- NULL
  u$fragment <- NULL

  res <- httr2::url_build(u)
  res <- sub("/$", "", res)
  return(res)
}
