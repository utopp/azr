

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
  names <- gsub(" ", " ", names, fixed = TRUE)
  for (i in seq_along(x)) {
    cli::cli_li("{.field {names[[i]]}}: {vals[[i]]}")
  }
}

list_redact <- function (x, names, case_sensitive = TRUE)
{
  if (case_sensitive) {
    i <- match(names, names(x))
  }
  else {
    i <- match(tolower(names), tolower(names(x)))
  }
  x[i] <- list(redacted())
  x
}

redacted <- function(){
  structure(list(NULL), class = "redacted")
}

format.redacted <- function (x, ...)
{
  cli::col_grey("<REDACTED>")
}

