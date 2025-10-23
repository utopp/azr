
# azr

<!-- badges: start -->
[![R-CMD-check](https://github.com/utopp/azr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/utopp/azr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

azr implements a credential chain for seamless OAuth 2.0 authentication to Azure services. It builds on [httr2](https://httr2.r-lib.org/)'s OAuth framework to provide automatic credential discovery, trying different authentication methods in sequence until one succeeds.

The package supports:

* **Client Secret Credential**: Service principal authentication with client ID and secret
* **Azure CLI Credential**: Leverages existing Azure CLI (`az`) login
* **Authorization Code Flow**: Interactive browser-based authentication
* **Device Code Flow**: Authentication for headless or CLI environments

During interactive development, azr allows browser-based login flows, while in batch/production mode it seamlessly falls back to non-interactive methods.

## Installation

You can install the development version of azr from [GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("utopp/azr")
```

## Usage

### Quick start with automatic credential discovery

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

### Using credential classes directly

You can also instantiate specific credential classes when you know which authentication method you want to use:

#### Azure CLI authentication

If you're already logged in via `az login`, this is the easiest option:

``` r
# Create an Azure CLI credential
cred <- AzureCLICredential$new(
  tenant_id = "your-tenant-id",
  scope = "https://management.azure.com/.default"
)

# Get a token
token <- cred$get_token()

# Or use directly with httr2 requests
req <- request("https://management.azure.com/subscriptions") |>
  cred$req_auth()

resp <- req_perform(req)
```

#### Client secret authentication

For service principal authentication in production:

``` r
# Create a client secret credential
cred <- ClientSecretCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  scope = "https://management.azure.com/.default"
)

# Use with httr2
req <- request("https://management.azure.com/subscriptions") |>
  cred$req_auth()

resp <- req_perform(req)
```

#### Interactive authentication

For user authentication during development:

``` r
# Device code flow (shows a code to enter in browser)
cred <- DeviceCodeCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  scope = "https://graph.microsoft.com/.default"
)

token <- cred$get_token()

# Authorization code flow (opens browser automatically)
cred <- AuthCodeCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  scope = "https://graph.microsoft.com/.default"
)

token <- cred$get_token()
```

### Customizing the credential chain

You can customize which authentication methods are tried and in what order:

``` r
# Define a custom credential chain
custom_chain <- list(
  AzureCLICredential,
  ClientSecretCredential
)

# Use the custom chain
token <- get_token(
  tenant_id = "your-tenant-id",
  scope = "https://management.azure.com/.default",
  .chain = custom_chain
)
```

## Common Azure scopes

- Azure Resource Manager: `https://management.azure.com/.default`
- Microsoft Graph: `https://graph.microsoft.com/.default`
- Azure Storage: `https://storage.azure.com/.default`
- Azure Key Vault: `https://vault.azure.net/.default`

## Code of Conduct

Please note that the azr project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
