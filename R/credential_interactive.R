#' Azure Authorization Code Credential
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
InteractiveCredential <- R6::R6Class(
  classname = "InteractiveCredential",
  inherit = Credential,
  private = list(
    flow = NULL,
    req_auth_fun = NULL
  )
  ,
  public = list(
    initialize = function(scope =  NULL,
                          tenant_id = NULL,
                          client_id =  NULL,
                          use_cache = "disk",
                          offline = TRUE,
                          oauth_host = NULL
    ) {

      oauth_endpoint <- check_capability()

      if(oauth_endpoint == "devicecode"){
        private$flow <- httr2::oauth_flow_device
        private$req_auth_fun <- httr2::req_oauth_device
      } else {
        private$flow <- httr2::oauth_flow_auth_code
        private$req_auth_fun <- httr2::req_oauth_auth_code
      }

      super$initialize(scope = scope,
                      tenant_id = tenant_id,
                      client_id = client_id,
                      use_cache = use_cache,
                      offline = offline,
                      oauth_host = oauth_host,
                      oauth_endpoint = oauth_endpoint)
    }
    ,
    #' @description
    #' Get an access token using device code flow
    #' @param scope Character vector of scopes to request (optional, uses initialized scope if not provided)
    #' @return A list containing the access token and expiration time
    get_token = function(reauth = FALSE) {

      httr2::oauth_token_cached(client = self$.oauth_client,
                                flow = private$flow,
                                cache_disk = self$.use_cache == "disk",
                                cache_key = self$.cache_key,
                                flow_params = list(scope = self$.str_scope,
                                                   auth_url = self$.oauth_url),
                                reauth = reauth)

    }
    ,
    #' @description
    #' Add authentication to an httr2 request
    #' @param req An httr2 request object
    #' @param scopes Optional scope(s) to request (uses initialized scope if not provided)
    #' @return An httr2 request object with bearer token authentication added
    req_auth = function(req){

      private$req_auth_fun(
        req = req,
        client = self$.oauth_client,
        auth_url = self$.oauth_url,
        scope = self$.str_scope,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key
      )
    }
  )
)


check_capability <- function(){
  if(!is_host_session()){
    if(!rlang::is_installed("httpuv")){
      cli::cli_inform("Install package {.pkg httpuv} to enable Authorization Code Flow",
                      .frequency = "once",
                      .frequency_id = "httpuv")
      return("devicecode")
    } else {
      return("authorize")
    }
  } else {
    return("devicecode")
  }
}

is_host_session <- function(){
  if (nzchar(Sys.getenv("COLAB_RELEASE_TAG"))) {
    return(TRUE)
  }
  Sys.getenv("RSTUDIO_PROGRAM_MODE") == "server" &&
    !grepl("localhost", Sys.getenv("RSTUDIO_HTTP_REFERER"), fixed = TRUE)
}

collapse_scope = function(scope){
  paste(scope, collapse = " ")
}
