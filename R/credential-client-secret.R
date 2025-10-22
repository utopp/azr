
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

      if(is.null(self$.client_secret) || rlang::is_na(self$.client_secret))
        cli::cli_abort("Argument {.arg client_secret} cannot be NULL or NA.")
    }
    ,
    get_token = function() {
      httr2::oauth_flow_client_credentials(client = self$.oauth_client,
                                           scope = self$.scope_str)
    }
    ,
    req_auth = function(req){
      httr2::req_oauth_client_credentials(
        req = req,
        client = self$.oauth_client,
        scope = self$.str_scope
      )
    }
  )
)
