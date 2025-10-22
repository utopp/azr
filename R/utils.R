validate_tenant_id <- function(x) {
  if (!rlang::is_string(x)) {
    cli::cli_abort("input must be a character vector")
  }

  for (y in x) {
    if (!grepl("^[A-Za-z0-9.-]+$", y)) {
      cli::cli_abort("tenant id {.val {y}} is not valid")
    }
  }
  TRUE
}


validate_scope <- function(x) {
  if (!rlang::is_character(x)) {
    cli::cli_abort("input must be a character vector")
  }

  for (y in x) {
    if (!grepl("^[A-Za-z0-9_.:/-]+$", y)) {
      cli::cli_abort("scope {.val {x}} is not valid")
    }
  }
  TRUE
}


get_scope_resource <- function(scope) {
  x <- grep("^http", scope, value = TRUE, ignore.case = TRUE)

  if(length(x) != 1L)
    return(NULL)

  u <- httr2::url_parse(x)
  u$path <- NULL
  u$query <- NULL
  u$fragment <- NULL

  res <- httr2::url_build(u)
  res <- sub("/$", "", res)
  return(res)
}


r6_get_initialize_arguments <- function(cls){

  if(!R6::is.R6Class(cls))
    cli::cli_abort("Argument {.arg cls} must the a R6 Class.")

  if(is.null(cls$public_methods$initialize))
    return(r6_get_initialize_arguments(cls$get_inherit()))

  names(formals(cls$public_methods$initialize))
}


r6_get_public_fields <- function(cls){

  if(!R6::is.R6Class(cls))
    cli::cli_abort("Argument {.arg cls} must the a R6 class.")

  res <- names(cls$public_fields)
  sup <- cls$get_inherit()

  if(!is.null(sup))
    return(c(res, r6_get_public_fields(sup)))

  res
}


r6_get_class <- function(obj){

  if(!R6::is.R6(obj))
    cli::cli_abort("Argument {.arg obj} must the a R6 object.")

  get(class(obj)[[1]], envir = getNamespace(methods::getPackageName()))
}


`%|||%` <- function(x,y){
  if (is_empty(x))
    y
  else x
}

is_empty <- function(x){
  is.null(x) || (rlang::is_scalar_vector(x) && (rlang::is_empty(x) || is.na(x) || !nzchar(x)))
}


