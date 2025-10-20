
default_azure_tenant_id <- function() {
  Sys.getenv(EnvironmentVariables$AZURE_TENANT_ID,
             unset = AzureClient$TENANT_ID)
}


default_azure_client_id <- function() {
  Sys.getenv(EnvironmentVariables$AZURE_CLIENT_ID,
             unset = AzureClient$CLIENT_ID)
}


default_azure_scope <- function(resource = "AZURE_ARM") {
  resource <- rlang::arg_match(resource, values = names(AzureScopes))
  AzureScopes[[resource]]
}

default_azure_oauth_client <- function(client_id = default_azure_client_id(),
                                       client_secret = NULL,
                                       name = NULL) {
  if (is.null(name)) {
    name <- rlang::hash(client_id)
  }

  client <- httr2::oauth_client(
    name = name,
    id = client_id,
    token_url = default_azure_url("token"),
    secret = client_secret,
    auth = "body"
  )
}


default_azure_url <- function(what = NULL,
                              auth_host = "AZURE_PUBLIC_CLOUD",
                              tenant_id = default_azure_tenant_id()) {

  auth_host <- rlang::arg_match(auth_host, values = names(AzureAuthorityHosts))
  auth_host_url <- AzureAuthorityHosts[[auth_host]]

  validate_tenant_id(tenant_id)

  oauth_base <- glue::glue_safe("https://{auth_host_url}/{tenant_id}/oauth2/v2.0")
  authorize_url <- glue::glue_safe("{oauth_base}/authorize")
  token_url <- glue::glue_safe("{oauth_base}/token")
  device_url <- glue::glue_safe("{oauth_base}/devicecode")

  ls_urls <- list(authorize = authorize_url,
                  token = token_url,
                  device = device_url)

  if(!is.null(what)) {
    what <- rlang::arg_match(what, values = names(ls_urls))
    return(ls_urls[[what]])
  }

  ls_urls
}
