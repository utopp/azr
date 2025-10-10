#

azure_default_credentials <- function(scope = azure_default_scope(),
                                      client_id = azure_default_client_id(),
                                      client_secret = NULL,
                                      cache_disk = TRUE,
                                      auth_type = NULL) {
  if (is.null(auth_type)) {
    auth_type <- select_auth_type(client_id, client_secret)
  }

  stopifnot(is_defined(scope), is_defined(client_id))

  switch(auth_type,
         client_credentials = make_oauth_client_credentials(scope, client_id, client_secret),
         azure_cli = make_oauth_azure_cli(resource = get_scope_resource(scope)),
         auth_code = make_oauth_auth_code(scope = scope, client_id = client_id, cache_disk = cache_disk),
         device_code = make_oauth_device_code(scope = scope, client_id = client_id, cache_disk = cache_disk)
  )
}

select_auth_type <- function(client_id = azure_default_client_id(),
                             client_secret = NULL) {
  if (is_defined(client_id) && is_defined(client_secret)) {
    return("client_credentials")
  }

  if (azure_cli_available()) {
    user <- try(azure_cli_get_user(), silent = TRUE)

    if (!is.null(user)) {
      return("azure_cli")
    }
  }

  if (interactive()) {
    if (Sys.getenv("RSTUDIO_PROGRAM_MODE") == "desktop") {
      return("auth_code")
    }

    return("device_code")
  } else {
    stop("non interactive session require 'client_credentials'.", call. = FALSE)
  }
}

select_auth_credentials <- function(scope = azure_default_scope(),
                                    client_id = azure_default_client_id(),
                                    client_secret = NULL,
                                    default_scope = azure_default_scope()) {
  auth_type <- select_auth_type(client_id, client_secret)

  if (auth_type != "client_credentials") {
    scope <- default_scope
    client_secret <- NULL
  }

  list(
    scope = scope,
    client_id = client_id,
    client_secret = client_secret,
    auth_type = auth_type
  )
}

make_oauth_auth_code <- function(scope, client_id, cache_disk = TRUE) {
  client <- azure_default_oauth_client(client_id = client_id)
  auth_url <- azure_default_url("authorize")

  fun <- function(req) {
    httr2::req_oauth_auth_code(
      req = req,
      client = client,
      auth_url = auth_url,
      scope = paste(scope, collapse = " "),
      cache_disk = cache_disk,
      cache_key = scope
    )
  }

  attr(fun, which = "creds") <- list(
    auth_type = "auth_code",
    scope = scope,
    client_id = client_id
  )
  return(fun)
}

make_oauth_device_code <- function(scope, client_id, cache_disk = TRUE) {
  client <- azure_default_oauth_client(client_id = client_id)
  auth_url <- azure_default_url("device")

  fun <- function(req) {
    httr2::req_oauth_device(
      req = req,
      client = client,
      auth_url = auth_url,
      scope = paste(scope, collapse = " "),
      cache_disk = cache_disk,
      cache_key = scope
    )
  }

  attr(fun, which = "creds") <- list(
    auth_type = "device_code",
    scope = scope,
    client_id = client_id
  )
  return(fun)
}

make_oauth_client_credentials <- function(scope, client_id, client_secret) {
  client <- azure_default_oauth_client(
    name = rlang::hash(c(client_id, scope)),
    client_id = client_id,
    client_secret = client_secret
  )

  fun <- function(req) {
    httr2::req_oauth_client_credentials(
      req = req,
      client = client,
      scope = paste(scope, collapse = " ")
    )
  }

  attr(fun, which = "creds") <- list(
    auth_type = "client_credentials",
    scope = scope,
    client_id = client_id,
    client_secret = "******"
  )
  return(fun)
}

make_oauth_azure_cli <- function(resource) {
  fun <- function(req) {
    token <- azure_get_cli_token(resource)

    if (is.null(token)) {
      cli::cli_alert_warning("failed to get token from azure cli for scope = {resource}")
      stop("Azure CLI request for token failed.", call. = FALSE)
    }

    httr2::req_auth_bearer_token(req, token$access_token)
  }

  attr(fun, which = "creds") <- list(
    auth_type = "azure_cli",
    resource = resource,
    client_id = azure_default_client_id()
  )

  return(fun)
}

azure_default_oauth_client <- function(client_id = NULL,
                                       client_secret = NULL,
                                       name = NULL) {
  client_id <- client_id %||% azure_default_client_id()

  if (is.null(name)) {
    name <- rlang::hash(client_id)
  }

  client <- httr2::oauth_client(
    name = name,
    id = client_id %||% azure_default_client_id(),
    token_url = azure_default_url("token"),
    secret = client_secret,
    auth = "body"
  )
}

azure_default_client_id <- function() {
  # Azure CLI
  "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
}

azure_default_scope <- function(resource = c("arm", "graph"), scope = "offline_access") {
  resource <- match.arg(resource)

  ls_resource <- list(
    arm = "https://management.azure.com/.default",
    graph = "https://graph.microsoft.com/.default"
  )

  unique(c(ls_resource[[resource]], scope))
}

azure_default_tenant <- function() {
  "common"
}

azure_default_url <- function(what = c("authorize", "token", "device"),
                              tenant_id = azure_default_tenant()) {

  what <- match.arg(what, several.ok = TRUE)
  what <- paste0(what, "_url")

  authorize_url <- sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/authorize", tenant_id)
  token_url <- sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/token", tenant_id)
  device_url <- sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/devicecode", tenant_id)

  res <- list(authorize_url = authorize_url, token_url = token_url, device_url = device_url)

  if (length(what) == 1L) {
    res[[what]]
  } else {
    res
  }
}

is_defined <- function(x) {
  length(x) > 1L || (length(x) && !is.na(x) && nzchar(x))
}

