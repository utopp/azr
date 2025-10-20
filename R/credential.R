#' Azure Credential
#'
#' @description
#' Base Credential class.
#'
#' @export
Credential <- R6::R6Class(
  classname = "Credential",
  public = list(
    .id = NULL,
    .scope = NULL,
    .resource = NULL,
    .client_id = NULL,
    .client_secret = NULL,
    .tenant_id = NULL,
    .cache_disk = NULL,
    .cache_key = NULL,
    .auth_client = NULL,
    .auth_host = NULL,
    .auth_url = NULL,
    .token_url = NULL,
    #' @description
    #' Initialize the Credential
    #' @param scope The scope(s) to request access for
    #' @param client_id The client ID of the application
    #' @param cache_disk Whether to cache tokens to disk (default: TRUE)
    #' @return A new `Credential` object
    initialize = function(scope =  NULL,
                          tenant_id = NULL,
                          client_id =  NULL,
                          client_secret = NULL,
                          cache_disk = TRUE,
                          auth_host = "AZURE_PUBLIC_CLOUD",
                          auth_url = NULL
    ) {
      self$.scope <- scope %||% default_azure_scope(resource = "AZURE_ARM")
      self$.resource <- get_scope_resource(self$.scope)

      self$.client_id <- client_id %||% default_azure_client_id()
      self$.client_secret <- client_secret

      self$.tenant_id <- tenant_id %||% default_azure_tenant_id()
      self$.cache_disk <- cache_disk

      self$.cache_key <- c(self$.client_id, self$.tenant_id, self$.scope)
      self$.id <- rlang::hash(self$.cache_key)

      self$.token_url <- default_azure_url(what = "token",
                                           auth_host = auth_host,
                                           tenant_id = self$.tenant_id)
      self$.auth_url <- auth_url

      self$.auth_client <- httr2::oauth_client(
        name = self$.id,
        id = self$.client_id,
        token_url = self$.token_url,
        secret = self$.client_secret,
        auth = "body"
      )
    }
  )
)
