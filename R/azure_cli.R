

AzureCliCredential <- R6::R6Class(
  classname = "AzureCliCredential",

  public = list(
    tenant_id = NULL,
    .process_timeout = 10,

    #' @description
    #' Initialize the AzureCliCredential
    #' @param tenant_id Optional tenant ID to use for authentication
    #' @param process_timeout Timeout in seconds for CLI process (default: 10)
    initialize = function(tenant_id = NULL,
                          process_timeout = 10) {

      self$tenant_id <- tenant_id
      seld$.process_timeout <- process_timeout
    },

    #' @description
    #' Get an access token using Azure CLI
    #' @param scopes  Sgingle scope to request (default: Azure Resource Manager)
    #' @return A list containing the access token and expiration time
    get_token = function(scopes = azure_default_scope("arm")) {

      .az_cli_run(scope = scope, tenant_id = self$tenant_id, timeout = self$.process_timeout)
    }
  )
)


.az_cli_run <-  function(scope, tenant_id = NULL, timeout = 10){

  args <- c("account", "get-access-token", "--output", "json")
  az_path <- Sys.which("az")

  if(!nzchar(az_path))
    rlang::abort("Azure CLI not found on path")

  validate_scope(scope)
  resource <- .scope_to_resource(scope)

  args <- append(args, c("--resource", resource, "--scope", scope))

  if(is.null(tenant_id)){
    validate_tenant_id(tenant_id)
    args <- append(args, c("--tenant", tenant_id))
  }

  env <- c(AZURE_CORE_NO_COLOR="true")

  output <- system2(command = az_path,
                    args = args,
                    stdout = TRUE,
                    stderr = TRUE,
                    timeout = timeout,
                    env = env)

  attr_output <- attributes(output)

  if (!is.null(attr_output) && attr_output$status == 1L) {
    cli::cli_abort("azure cli returned error:\n {output}")
  }

  token <- jsonlite::fromJSON(output)

  httr2::oauth_token(
    access_token = token$accessToken,
    token_type = token$tokenType,
    expires_in = token$expires_on
  )
}


.scope_to_resource <- function(x){

  if(!rlang::is_bare_string(x))
    rlang::abort("This credential requires exactly one scope per token request.")

  u <- httr2::url_parse(x)
  u$path <- NULL

  sub("/$", "", httr2::url_build(u))
}
