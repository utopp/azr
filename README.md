
# azr

<!-- badges: start -->
[![R-CMD-check](https://github.com/utopp/azr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/utopp/azr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

azr implements a credential chain for seamless OAuth 2.0 authentication to Azure services. It builds on [httr2](https://httr2.r-lib.org/)'s OAuth framework to provide cache and automatic credential discovery, trying different authentication methods in sequence until one succeeds.

## Installation

You can install the development version of azr from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("utopp/azr")
```

## Overview

The package supports:

* **Client Secret Credential**: Service principal authentication with client ID and secret
* **Azure CLI Credential**: Leverages existing Azure CLI (`az`) login
* **Authorization Code Flow**: Interactive browser-based authentication
* **Device Code Flow**: Authentication for headless or CLI environments

During interactive development, azr allows browser-based login flows, while in batch/production mode it seamlessly falls back to non-interactive methods.

## Related work

azr is inspired by Python's [azure-identity](https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme) library, which provides comprehensive coverage of Azure authentication scenarios and introduced the credential chain pattern for automatic authentication method discovery.

The R package [AzureAuth](https://github.com/Azure/AzureAuth) (based on [httr](https://httr.r-lib.org/)) also provides token acquisition for Azure services, but does not offer an explicit way to define credential chains. This becomes important in scenarios where different authentication methods require different configurations. For example:

- **Client Secret Credentials**: Using a service principal `client_id` with an application-specific `scope`
- **Interactive Credentials**: Using user authentication with different credentials

azr addresses this by allowing you to define custom credential chains with method-specific configurations, enabling seamless fallback between authentication approaches.

## Usage

The simplest way to authenticate is using `get_token()`, which automatically tries different authentication methods until one succeeds:

``` r
library(azr)

# Get a token using the default credential chain
token <- get_token(
  tenant_id = "your-tenant-id",
  scope = "https://management.azure.com/.default"
)

# Use the token with httr2
library(httr2)
req <- request("https://management.azure.com/subscriptions") |>
  req_auth_bearer_token(token$access_token)

resp <- req_perform(req)
```

Alternatively, use `get_request_authorizer()` to get a function that adds authentication to requests:

``` r
library(azr)
library(httr2)

# Get a request authorizer for Microsoft Graph API
azr_req_auth <- get_request_authorizer(
  tenant_id = "your-tenant-id",
  scope = "https://graph.microsoft.com/.default"
)

# Use it to authenticate requests
resp <- request("https://graph.microsoft.com/v1.0/me") |>
  azr_req_auth() |>
  req_perform()
```

You can customize which authentication methods are tried and in what order:

``` r
# Define a custom credential chain with specific credential instances
custom_chain <- list(
  ClientSecretCredential$new(
    scope = Sys.getenv("APP_SCOPE"),
    client_id = Sys.getenv("APP_CLIENT_ID"),
    client_secret = Sys.getenv("APP_CLIENT_SECRET")
  ),
  AzureCLICredential
)

# Use the custom chain
token <- get_token(
  tenant_id = "your-tenant-id",
  scope = "https://management.azure.com/.default",
  .chain = custom_chain
)
```

## Code of Conduct

Please note that the azr project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
