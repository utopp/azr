#' Azure Device Code Credential
#'
#' @description
#' Authenticates using the device code flow to obtain access tokens.
#'
#' @details
#' This credential authenticates a user through the device code flow. The user must
#' navigate to a URL and enter a provided code to complete authentication.
#' Supports token caching to disk for persistence across sessions.
#'
#' @export
DeviceCodeCredential <- R6::R6Class(
  classname = "DeviceCodeCredential",
  inherit = Credential,
  public = list(
    #' @description
    #' Initialize the DeviceCodeCredential
    #' @param scope The scope(s) to request access for
    #' @param client_id The client ID of the application
    #' @param cache_disk Whether to cache tokens to disk (default: TRUE)
    #' @return A new `DeviceCodeCredential` object
    initialize = function(scope = NULL,
                          client_id = NULL,
                          tenant_id = NULL,
                          cache_disk = TRUE,
                          auth_host = "AZURE_PUBLIC_CLOUD") {

      super$initialize(scope = scope,
                       tenant_id = tenant_id,
                       client_id = client_id,
                       cache_disk = cache_disk,
                       auth_host =  auth_host)

      self$.auth_url <- default_azure_url("device",
                                          auth_host = self$.auth_host,
                                          tenant_id = self$.tenant_id)
    },

    #' @description
    #' Get an access token using device code flow
    #' @param scopes Character vector of scopes to request (optional, uses initialized scope if not provided)
    #' @return A list containing the access token and expiration time
    get_token = function(scope = NULL, reauth = FALSE) {
      httr2::oauth_token_cached(client = self$.auth_client,
                                flow = httr2::oauth_flow_device,
                                cache_disk = self$.cache_disk,
                                cache_key = self$.cache_key,
                                flow_params = list(scope = paste(self$.scope, collapse = " "),
                                                   auth_url = self$.auth_url,
                                                   client = self$.auth_client),
                                reauth = reauth)
    }
    ,
    #' @description
    #' Add authentication to an httr2 request
    #' @param req An httr2 request object
    #' @param scopes Optional scope(s) to request (uses initialized scope if not provided)
    #' @return An httr2 request object with bearer token authentication added
    req_auth = function(req, scopes = NULL){
      scope <-
      httr2::req_oauth_device(
        req = req,
        client = self$.auth_client,
        auth_url = self$.auth_url,
        scope = paste(self$.scope, collapse = " "),
        cache_disk = self$.cache_disk,
        cache_key = self$.cache_key
      )
    }
  )
)
