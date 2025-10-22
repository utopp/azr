
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
                            chain = default_credential_chain()){
  for(cls in chain){

    if(isTRUE(cls$is_interactive) && !rlang::is_interactive()){
      cli::cli_alert_warning("Non-iteractive Session. Skipping {.cls {cls$classname}}.")
      next
    } else {
      cli::cli_alert_info("Trying: {.cls {cls$classname}}.")
    }

    cls_args <- r6_get_initialize_arguments(cls)
    cls_values <- rlang::env_get_list(nms = cls_args, default = NULL)

    crd <- try(eval(rlang::call2(cls$new, !!!cls_values)), silent = TRUE)

    if(inherits(crd, "Credential")){
      token <- tryCatch(crd$get_token(),
                        error = function(e){
                          cli::cli_alert_danger("Unsucessful")
                        }
                        ,
                        interrupt = function(e) {
                          cli::cli_alert_danger("Interrupted.")
                        })

      if(inherits(token, "httr2_token")){
        cli::cli_alert_success("Sucessful")
        return(crd)
      }
    }
  }
  cli::cli_abort("Failed to find credentials.")
}


default_credential_chain <- function(){
  list(ClientSecretCredential, AzureCLICredential, InteractiveCredential)
}


