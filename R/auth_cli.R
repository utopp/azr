azure_get_cli_token <- function(resource) {
  if (missing(resource)) {
    resource <- get_scope_resource(azure_default_scope())
  }

  output <- try(suppressWarnings(system2(
    command = "az",
    args = c("account", "get-access-token", "--resource", resource),
    stdout = TRUE,
    stderr = TRUE
  )), silent = TRUE)

  if (inherits(output, "try-error")) {
    cli::cli_alert_warning("azure cli failed")
    return(invisible(NULL))
  }

  attr_output <- attributes(output)

  if (!is.null(attr_output) && attr_output$status == 1L) {
    cli::cli_alert_warning("azure cli returned error:\n {output}")
    return(invisible(NULL))
  }

  token <- try(
    {
      x <- jsonlite::fromJSON(output)
      httr2::oauth_token(
        access_token = x$accessToken,
        token_type = x$tokenType,
        expires_in = x$expires_on
      )
    },
    silent = TRUE
  )

  if (inherits(token, "try-error")) {
    cli::cli_warn("failed to parse json token")
    return(NULL)
  }

  return(token)
}

azure_cli_get_user <- function() {
  res <- suppressWarnings(system2("az", c("account", "show"),
                                  stdout = TRUE,
                                  stderr = TRUE
  ))

  attr_output <- attributes(res)

  if (!is.null(attr_output) && attr_output$status == 1L) {
    return(NULL)
  }

  jsonlite::fromJSON(res)
}

azure_cli_available <- function() {
  x <- Sys.which("az")
  (!is.na(x) && nzchar(x, keepNA = TRUE))
}

get_scope_resource <- function(x) {
  x <- grep("^http", x, value = TRUE)

  stopifnot(length(x) == 1L)

  u <- httr2::url_parse(x)
  u$path <- NULL
  u$query <- NULL
  u$fragment <- NULL

  res <- httr2::url_build(u)
  res <- sub("/$", "", res)
  return(res)
}
