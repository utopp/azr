
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
                          offline = TRUE
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
                      oauth_endpoint = oauth_endpoint)
    }
    ,
    get_token = function(reauth = FALSE) {

      httr2::oauth_token_cached(client = self$.oauth_client,
                                flow = private$flow,
                                cache_disk = self$.use_cache == "disk",
                                cache_key = self$.cache_key,
                                flow_params = list(scope = self$.scope_str,
                                                   auth_url = self$.oauth_url),
                                reauth = reauth)

    }
    ,
    req_auth = function(req){

      private$req_auth_fun(
        req = req,
        client = self$.oauth_client,
        auth_url = self$.oauth_url,
        scope = self$.scope_str,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key
      )
    }
  )
)

InteractiveCredential$is_interactive <- TRUE

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
