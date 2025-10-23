# DeviceCodeCredential ----
DeviceCodeCredential <- R6::R6Class(
  classname = "DeviceCodeCredential",
  inherit = InteractiveCredential,
  ,
  public = list(
    initialize = function(scope =  NULL,
                          tenant_id = NULL,
                          client_id =  NULL,
                          use_cache = "disk",
                          offline = TRUE
    ) {

      super$initialize(scope = scope,
                       tenant_id = tenant_id,
                       client_id = client_id,
                       use_cache = use_cache,
                       offline = offline,
                       oauth_endpoint = "devicecode")
    }
    ,
    get_token = function(reauth = FALSE) {

      httr2::oauth_token_cached(client = self$.oauth_client,
                                flow = httr2::oauth_flow_device,
                                cache_disk = self$.use_cache == "disk",
                                cache_key = self$.cache_key,
                                flow_params = list(scope = self$.scope_str,
                                                   auth_url = self$.oauth_url),
                                reauth = reauth)

    }
    ,
    req_auth = function(req){

      httr2::req_oauth_device(
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


# AuthCodeCredential ----
AuthCodeCredential <- R6::R6Class(
  classname = "AuthCodeCredential",
  inherit = InteractiveCredential,
  ,
  public = list(
    initialize = function(scope =  NULL,
                          tenant_id = NULL,
                          client_id =  NULL,
                          use_cache = "disk",
                          offline = TRUE,
                          redirect_uri = default_redirect_uri()
    ) {
      super$initialize(scope = scope,
                       tenant_id = tenant_id,
                       client_id = client_id,
                       use_cache = use_cache,
                       offline = offline,
                       oauth_endpoint = "authorize")

      self$.redirect_uri <- default_redirect_uri()
    }
    ,
    get_token = function(reauth = FALSE) {

      httr2::oauth_token_cached(client = self$.oauth_client,
                                flow = httr2::oauth_flow_auth_code,
                                cache_disk = self$.use_cache == "disk",
                                cache_key = self$.cache_key,
                                flow_params = list(scope = self$.scope_str,
                                                   auth_url = self$.oauth_url,
                                                   redirect_uri = self$.redirect_uri),
                                reauth = reauth)

    }
    ,
    req_auth = function(req){

      httr2::req_oauth_auth_code(
        req = req,
        client = self$.oauth_client,
        auth_url = self$.oauth_url,
        scope = self$.scope_str,
        redirect_uri = self$.redirect_uri,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key
      )
    }
  )
)


InteractiveCredential <- R6::R6Class(
  classname = "InteractiveCredential",
  inherit = Credential,
  public = list(
    is_interactive = function(){TRUE}
  ))
