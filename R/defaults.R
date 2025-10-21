
default_azure_token <- function(scope =  NULL,
                                tenant_id = NULL,
                                client_id =  NULL,
                                client_secret = NULL,
                                use_cache = c("disk", "memory"),
                                offline = FALSE,
                                oauth_host = NULL,
                                oauth_endpoint = NULL){

  cli::cli_alert_info("Trying: Client Secret Credential")

  creds <- try({
    ClientSecretCredential$new(
      scope = scope,
      tenant_id = tenant_id,
      client_id = client_id,
      client_secret = client_secret,
      oauth_host = oauth_host)
  },
  silent = TRUE)

  if(inherits(creds, "Credential")){
    token <- try(creds$get_token(), silent = TRUE)

    if(inherits(token, "httr2_token")){
      cli::cli_alert_success("Sucessful")
      return(creds$get_token)
    }
  }

  cli::cli_alert_danger("Unsucessful")

  cli::cli_alert_info("Trying: Azure CLI Credential")

  creds <- try({
    AzureCLICredential$new(
      scope = scope,
      tenant_id = tenant_id)
  },
  silent = TRUE)

  if(inherits(creds, "Credential")){
    token <- try(creds$get_token(), silent = TRUE)

    if(inherits(token, "httr2_token")){
      return(creds$get_token)
      cli::cli_alert_success("Sucessful")
    }
  }

  cli::cli_alert_danger("Unsucessful")

  if(!interactive()){
    cli::cli_abort("Failed to find valid Credential for non-iteractive flows.")
  }

  cli::cli_alert_info("Trying: Interactive Flow")

  creds <- try({
    AzureCLICredential$new(
      scope = scope,
      tenant_id = tenant_id)
  },
  silent = TRUE)

  if(inherits(creds, "Credential")){
    token <- try(creds$get_token(), silent = TRUE)

    if(inherits(token, "httr2_token")){
      return(creds$get_token)
      cli::cli_alert_success("Sucessful")
    }
  }
  cli::cli_alert_danger("Unsucessful")

  cli::cli_abort("Failed to find valid Credential.")
}


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
  client <- httr2::oauth_client(
    name = name,
    id = client_id,
    token_url = default_azure_url("token"),
    secret = client_secret,
    auth = "body"
  )
}


default_azure_url <- function(endpoint = NULL,
                              oauth_host = "AZURE_PUBLIC_CLOUD",
                              tenant_id = default_azure_tenant_id()) {

  oauth_host <- rlang::arg_match(oauth_host, values = names(AzureAuthorityHosts))
  oauth_host_url <- AzureAuthorityHosts[[oauth_host]]

  validate_tenant_id(tenant_id)

  oauth_base <- rlang::englue("https://{oauth_host_url}/{tenant_id}/oauth2/v2.0")

  ls_urls <- list(authorize = "authorize", token = "token", devicecode = "devicecode")
  ls_urls <- lapply(ls_urls, function(x)paste(oauth_base, x, sep = "/"))

  if(!is.null(endpoint)) {
    what <- rlang::arg_match(endpoint, values = names(ls_urls))
    return(ls_urls[[endpoint]])
  }

  ls_urls
}
