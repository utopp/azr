#' Get Default Token Provider Function
#'
#' Creates a token provider function that retrieves authentication credentials
#' and returns a callable token getter. This function handles the credential
#' discovery process and returns the token acquisition method from the
#' discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#'
#' @return A function that retrieves and returns an authentication token when
#'   called.
#'
#' @seealso [default_request_authorizer()], [get_token()]
#'
#' @examples
#' \dontrun{
#'   token_provider <- default_token_provider(
#'     scope = "https://graph.microsoft.com/.default",
#'     tenant_id = "my-tenant-id",
#'     client_id = "my-client-id",
#'     client_secret = "my-secret"
#'   )
#'   token <- token_provider()
#' }
#'
#' @export
default_token_provider <- function(scope =  NULL,
                                   tenant_id = NULL,
                                   client_id =  NULL,
                                   client_secret = NULL,
                                   use_cache = "disk",
                                   offline = FALSE){

  crd <- find_credential(scope = scope,
                         tenant_id = tenant_id,
                         client_id = client_id,
                         client_secret = client_secret,
                         use_cache = use_cache,
                         offline = offline)
  crd$get_token
}

#' Get Default Request Authorizer Function
#'
#' Creates a request authorizer function that retrieves authentication credentials
#' and returns a callable request authorization method. This function handles the
#' credential discovery process and returns the request authentication method
#' from the discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#'
#' @return A function that authorizes HTTP requests with appropriate credentials
#'   when called.
#'
#'
#' @seealso [default_token_provider()], [get_token()]
#'
#' @examples
#' \dontrun{
#'   authorizer <- default_request_authorizer(
#'     scope = "https://graph.microsoft.com/.default"
#'   )
#'   req <- authorizer(httr2::request(https://graph.microsoft.com/v1.0/me))
#' }
#'
#' @export
default_request_authorizer <- function(scope =  NULL,
                                       tenant_id = NULL,
                                       client_id =  NULL,
                                       client_secret = NULL,
                                       use_cache = "disk",
                                       offline = FALSE){

  crd <- find_credential(scope = scope,
                         tenant_id = tenant_id,
                         client_id = client_id,
                         client_secret = client_secret,
                         use_cache = use_cache,
                         offline = offline)
  crd$req_auth
}

#' Get Authentication Token
#'
#' Retrieves an authentication token using the default token provider. This is
#' a convenience function that combines credential discovery and token
#' acquisition in a single step.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#'
#' @return A character string containing the authentication token.
#'
#' @seealso [default_token_provider()], [default_request_authorizer()]
#'
#' @examples
#' \dontrun{
#'   token <- get_token(
#'     scope = "https://graph.microsoft.com/.default",
#'     tenant_id = "my-tenant-id",
#'     client_id = "my-client-id",
#'     client_secret = "my-secret"
#'   )
#' }
#'
#' @export
get_token <- function(scope =  NULL,
                      tenant_id = NULL,
                      client_id =  NULL,
                      client_secret = NULL,
                      use_cache = "disk",
                      offline = FALSE){

  provider <- default_token_provider(scope = scope,
                                     tenant_id = tenant_id,
                                     client_id = client_id,
                                     client_secret = client_secret,
                                     use_cache = use_cache,
                                     offline = offline)
  provider()
}


find_credential <- function(scope =  NULL,
                            tenant_id = NULL,
                            client_id =  NULL,
                            client_secret = NULL,
                            use_cache = "disk",
                            offline = FALSE,
                            oauth_host = NULL,
                            oauth_endpoint = NULL,
                            chain = default_credential_chain(),
                            verbose = FALSE){
  for(crd in chain){

    if(R6::is.R6Class(crd))
      obj <- try(new_instance(crd, env = rlang::current_env()), silent = TRUE)
    else
      obj <- crd

    if(obj$is_interactive() && !rlang::is_interactive()){
      cli::cli_alert_warning("Skipping {.cls {class(obj)[[1]]}} (non-interactive session)")
      next
    } else {
      cli::cli_alert_info("Trying: {.cls {class(obj)[[1]]}}")
    }

    if(inherits(obj, "Credential")){
      token <- tryCatch(obj$get_token(),
                        error = function(e){
                          if(isTRUE(verbose))
                            print(e)
                          else
                            cli::cli_alert_danger("Unsuccessful!")
                        }
                        ,
                        interrupt = function(e) {
                          cli::cli_alert_danger("Interrupted!")
                        })

      if(inherits(token, "httr2_token")){
        cli::cli_alert_success("Sucessful!")
        return(obj)
      }
    }
  }
  cli::cli_abort("All authentication methods of the chain failed!")
}


default_credential_chain <- function(){

  list(client_secret = ClientSecretCredential,
       azure_cli = AzureCLICredential,
       auth_code = AuthCodeCredential,
       device_code = DeviceCodeCredential)
}


new_instance <- function(cls, env = rlang::caller_env()){

  cls_args <- r6_get_initialize_arguments(cls)
  cls_values <- rlang::env_get_list(nms = cls_args, default = NULL, env = env)

  eval(rlang::call2(cls$new, !!!cls_values))
  }

