default_azure_tenant_id <- function() {
  Sys.getenv(
    environment_variables$azure_tenant_id,
    unset = azure_client$tenant_id
  )
}


default_azure_client_id <- function() {
  Sys.getenv(
    environment_variables$azure_client_id,
    unset = azure_client$client_id
  )
}


default_azure_client_secret <- function() {
  Sys.getenv(
    environment_variables$azure_client_secret,
    unset = NA_character_
  )
}


default_azure_scope <- function(resource = "azure_arm") {
  resource <- rlang::arg_match(resource, values = names(azure_scopes))
  azure_scopes[[resource]]
}


default_azure_oauth_client <- function(client_id = default_azure_client_id(),
                                       client_secret = NULL,
                                       name = NULL) {
  httr2::oauth_client(
    name = name,
    id = client_id,
    token_url = default_azure_url("token"),
    secret = client_secret,
    auth = "body"
  )
}


default_azure_url <- function(endpoint = NULL,
                              oauth_host = default_azure_host(),
                              tenant_id = default_azure_tenant_id()) {
  validate_tenant_id(tenant_id)

  oauth_base <- rlang::englue("https://{oauth_host}/{tenant_id}/oauth2/v2.0")

  urls <- c(
    authorize = paste0(oauth_base, "/authorize"),
    token = paste0(oauth_base, "/token"),
    devicecode = paste0(oauth_base, "/devicecode")
  )

  if (!is.null(endpoint)) {
    endpoint <- rlang::arg_match(endpoint, values = names(urls))
    return(urls[[endpoint]])
  }

  as.list(urls)
}


default_azure_host <- function() {
  Sys.getenv(
    environment_variables$azure_authority_host,
    unset = azure_authority_hosts$azure_public_cloud
  )
}


default_redirect_uri <- function(redirect_uri = httr2::oauth_redirect_uri()) {
  parsed <- httr2::url_parse(redirect_uri)

  if (is.null(parsed$port)) {
    rlang::check_installed("httpuv", "for desktop OAuth")
    parsed$port <- httpuv::randomPort()
  }

  httr2::url_build(parsed)
}
