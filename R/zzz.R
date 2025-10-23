.onAttach <- function(libname, pkgname) {
  packageStartupMessage(cli::format_inline(
    "{.pkg azr} {utils::packageVersion('azr')} | Azure OAuth 2.0 credential chain"
  ))

  tenant_id_env <- Sys.getenv("AZURE_TENANT_ID", unset = "")
  client_id_env <- Sys.getenv("AZURE_CLIENT_ID", unset = "")
  client_secret_env <- Sys.getenv("AZURE_CLIENT_SECRET", unset = "")
  authority_host_env <- Sys.getenv("AZURE_AUTHORITY_HOST", unset = "")

  # Build display values
  if (nzchar(tenant_id_env)) {
    tenant_id_msg <- cli::format_inline("  • AZURE_TENANT_ID: {.val {tenant_id_env}}")
  } else {
    tenant_id_msg <- cli::format_inline("  • AZURE_TENANT_ID: {.emph {default_azure_tenant_id()}} (default)")
  }

  if (nzchar(client_id_env)) {
    client_id_msg <- cli::format_inline("  • AZURE_CLIENT_ID: {.val {client_id_env}}")
  } else {
    client_id_msg <- cli::format_inline("  • AZURE_CLIENT_ID: {.emph {default_azure_client_id()}} (default)")
  }

  if (nzchar(client_secret_env)) {
    client_secret_msg <- cli::format_inline("  • AZURE_CLIENT_SECRET: {format(redacted())}")
  } else {
    client_secret_msg <- paste0("  • AZURE_CLIENT_SECRET: ", cli::col_grey("(not set)"))
  }

  if (nzchar(authority_host_env)) {
    authority_host_msg <- cli::format_inline("  • AZURE_AUTHORITY_HOST: {.val {authority_host_env}}")
  } else {
    authority_host_msg <- cli::format_inline("  • AZURE_AUTHORITY_HOST: {.emph {default_azure_host()}} (default)")
  }

  packageStartupMessage(cli::format_inline("Environment configuration:"))
  packageStartupMessage(tenant_id_msg)
  packageStartupMessage(client_id_msg)
  packageStartupMessage(client_secret_msg)
  packageStartupMessage(authority_host_msg)
}
