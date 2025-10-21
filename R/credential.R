#' Azure Credential
#'
#' @description
#' Base Credential class.
#'
#' @export
Credential <- R6::R6Class(
  classname = "Credential",
  public = list(
    .id = NULL,
    .scope = NULL,
    .str_scope = NULL,
    .resource = NULL,
    .client_id = NULL,
    .client_secret = NULL,
    .tenant_id = NULL,
    .use_cache = "disk",
    .cache_key = NULL,
    .oauth_client = NULL,
    .oauth_host = "AZURE_PUBLIC_CLOUD",
    .oauth_endpoint = NULL,
    .oauth_url = NULL,
    .token_url = NULL,
    #' @description
    #' Initialize the Credential
    #' @param scope The scope(s) to request access for
    #' @param client_id The client ID of the application
    #' @param cache_disk Whether to cache tokens to disk (default: TRUE)
    #' @return A new `Credential` object
    initialize = function(scope =  NULL,
                          tenant_id = NULL,
                          client_id =  NULL,
                          client_secret = NULL,
                          use_cache = c("disk", "memory"),
                          offline = FALSE,
                          oauth_host = NULL,
                          oauth_endpoint = NULL
    ) {
      self$.scope <- scope %||% default_azure_scope(resource = "AZURE_ARM")

      if(isTRUE(offline))
        self$.scope <-  unique(c(self$.scope, "offline"))

      self$.str_scope <- collapse_scope(self$.scope)

      self$.resource <- get_scope_resource(self$.scope)

      self$.client_id <- client_id %||% default_azure_client_id()
      self$.client_secret <- client_secret

      self$.tenant_id <- tenant_id %||% default_azure_tenant_id()
      self$.use_cache <- rlang::arg_match(use_cache)

      self$.cache_key <- c(self$.client_id, self$.tenant_id, self$.scope)
      self$.id <- rlang::hash(self$.cache_key)

      self$.oauth_host <- oauth_host %||% self$.oauth_host
      self$.token_url <- default_azure_url(endpoint = "token",
                                           oauth_host = self$.oauth_host,
                                           tenant_id = self$.tenant_id)

      self$.oauth_endpoint <- oauth_endpoint %||% self$.oauth_endpoint

      if(!is.null(self$.oauth_endpoint)){
        self$.oauth_url <- default_azure_url(endpoint = self$.oauth_endpoint,
                                             oauth_host = self$.oauth_host,
                                             tenant_id = self$.tenant_id)
      }

      self$.oauth_client <- httr2::oauth_client(
        name = self$.id,
        id = self$.client_id,
        secret = self$.client_secret,
        token_url = self$.token_url,
        auth = "body"
      )

      self$validate()
    }
    ,
    validate = function(){
      validate_scope(self$.scope)
      validate_tenant_id(self$.tenant_id)
      return(invisible(self))
    }
    ,
    print = function(){
      cli::cli_text(cli::style_bold("<", paste(class(self), collapse = "/"), ">"))
      #redacted <- list_redact(compact(x), c("secret", "key"))
      nms <- grep("^\\.[a-zA-Z].+$",ls(self, all.names = T), value = T)
      x <- rlang::env_get_list(env = self, nms = nms)
      bullets(x)
      return(invisible(self))
    }
  )
)


bullets <- function(x){
  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is.character(x)) {
        paste0("\"", x, "\"")
      }
      else {
        format(x)
      }
    }
    else {
      if (inherits(x, "redacted")) {
        format(x)
      }
      else {
        paste0("<", class(x)[[1L]], ">")
      }
    }
  }
  vals <- vapply(x, as_simple, character(1))
  names <- format(names(x))
  names <- gsub(".", "", names, fixed = TRUE)
  names <- gsub(" ", " ", names, fixed = TRUE)
  for (i in seq_along(x)) {
    cli::cli_li("{.field {names[[i]]}}: {vals[[i]]}")
  }
}
