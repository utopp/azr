
AzureCLICredential <- R6::R6Class(
  classname = "AzureCLICredential",
  inherit = Credential,
  public = list(
    .process_timeout = 10,
    initialize = function(scope = NULL,
                          tenant_id = NULL,
                          process_timeout = NULL) {
    # TODO remove from here
    #if(!rlang::is_bare_string(scope))
     #   cli::cli_abort("Argument {.arg scope} must be a single string, not a vector of length {length(scope)}.")

      super$initialize(scope = scope, tenant_id = tenant_id)
      self$.process_timeout <- process_timeout %||% self$.process_timeout
    }
    ,
    get_token = function(scope = NULL) {
      rlang::try_fetch(.az_cli_run(
        scope = scope %||% self$.scope,
        tenant_id = self$.tenant_id,
        timeout = self$.process_timeout
      ), error = function(cnd)rlang::abort(cnd$message, call = call("get_token")))
    }
    ,
    req_auth = function(req, scope = NULL){
      token <- self$get_token(scope)
      httr2::req_auth_bearer_token(req, token$access_token)
    }
  )
)


.az_cli_run <- function(scope, tenant_id = NULL, timeout = 10L) {

  args <- c("account", "get-access-token", "--output", "json")
  az_path <- Sys.which("az")

  if (!nzchar(az_path)) {
    rlang::abort("Azure CLI not found on path")
  }

  validate_scope(scope)
  args <- append(args, c("--scope", scope))

  if (!is.null(tenant_id)) {
    validate_tenant_id(tenant_id)
    args <- append(args, c("--tenant", tenant_id))
  }

  output <- suppressWarnings(system2(
    command = az_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE,
    timeout = timeout
  ))
  attr_output <- attributes(output)

  if (!is.null(attr_output) && attr_output$status == 1L)
    cli::cli_abort(output)

  token <- jsonlite::fromJSON(output)

  httr2::oauth_token(
    access_token = token$accessToken,
    token_type = token$tokenType,
    expires_in = token$expires_on
  )
}
