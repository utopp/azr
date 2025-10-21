#' Client Secret Credential
#'
#' @description
#' Authenticates using the authorization code flow to obtain access tokens.
#'
#' @details
#' This credential authenticates a user through the authorization code flow. The user must
#' navigate to a URL and enter a provided code to complete authentication.
#' Supports token caching to disk for persistence across sessions.
#'
#' @export
ClientSecretCredential <- R6::R6Class(
  classname = "ClientSecretCredential",
  inherit = Credential,
  private = list(
    flow = NULL,
    req_auth_fun = NULL,
    str_scope = NULL
  )
  ,
  public = list(
    validate = function() {
      super$validate()

      if(rlang::is_null(self$.client_secret) || rlang::is_na(self$.client_secret))
        cli::cli_abort("Argument {.arg client_secret} cannot be NULL or NA.")
    }
    ,
    #' @description
    #' Get an access token using device code flow
    #' @param scope Character vector of scopes to request (optional, uses initialized scope if not provided)
    #' @return A list containing the access token and expiration time
    get_token = function() {
      httr2::oauth_flow_client_credentials(client = self$.oauth_client,
                                           scope = self$.str_scope)
    }
    ,
    #' @description
    #' Add authentication to an httr2 request
    #' @param req An httr2 request object
    #' @return An httr2 request object with bearer token authentication added
    req_auth = function(req){
      httr2::req_oauth_client_credentials(
        req = req,
        client = self$.oauth_client,
        scope = self$.str_scope
      )
    }
  )
)
