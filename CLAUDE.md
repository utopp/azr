# CLAUDE.md - AI Assistant Guide for azr Package

This guide provides comprehensive information about the `azr` R package codebase for AI assistants working on this project.

## Project Overview

**Name:** azr
**Version:** 0.1.0 (Initial CRAN submission)
**License:** MIT
**Author:** Pedro Baltazar (pedrobtz@gmail.com)
**Purpose:** Azure OAuth 2.0 credential chain for seamless authentication to Azure services

The `azr` package implements a credential chain for automatic Azure authentication, inspired by Python's `azure-identity` library. It builds on httr2's OAuth framework to provide credential caching and automatic discovery, trying different authentication methods in sequence until one succeeds.

**Key Features:**
- Client Secret Credential (service principal authentication)
- Azure CLI Credential (leverages existing `az login`)
- Device Code Flow (headless/CLI authentication)
- Authorization Code Flow (interactive browser-based authentication)
- Automatic credential discovery and fallback
- Token caching (disk and memory)

## Directory Structure

```
/home/user/azr/
├── R/                          # R source code (1,309 lines)
│   ├── azr-package.R          # Package definition
│   ├── credential.R           # Base Credential R6 class (113 lines)
│   ├── credential-client-secret.R    # ClientSecretCredential (74 lines)
│   ├── credential-azure-cli.R # AzureCLICredential (124 lines)
│   ├── credential-interactive.R      # Interactive credentials (241 lines)
│   ├── default-credential.R   # Credential chain & main API (287 lines)
│   ├── constants.R            # Azure constants and defaults (54 lines)
│   ├── defaults.R             # Default configuration getters (208 lines)
│   ├── utils.R                # Utility functions (122 lines)
│   ├── import-funs.R          # Imported utility functions (69 lines)
│   └── zzz.R                  # Package initialization (10 lines)
│
├── man/                        # Auto-generated documentation (roxygen2)
├── .github/workflows/          # CI/CD workflows
│   ├── R-CMD-check.yaml       # Cross-platform R CMD check
│   ├── lint.yaml              # Code linting
│   ├── pkgdown.yaml           # Documentation site generation
│   └── pr-commands.yaml       # PR automation
│
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions (auto-generated)
├── README.md                   # User-facing documentation
├── NEWS.md                     # Release notes
├── LICENSE / LICENSE.md        # MIT license
├── azr.Rproj                   # RStudio project configuration
├── _pkgdown.yml                # Documentation site config
├── .lintr                      # Code linting rules
├── .Rbuildignore              # Build exclusions
└── .gitignore                 # Git ignore rules
```

## Technology Stack

**Language:** R (tidyverse ecosystem)

**Core Dependencies:**
- **httr2** - HTTP client with OAuth 2.0 framework (foundation for auth)
- **R6** - Object-oriented programming system (class definitions)
- **rlang** - Metaprogramming utilities
- **jsonlite** - JSON serialization
- **cli** - Command-line interface formatting
- **methods** - S3/S4 object system

**Suggested Dependencies:**
- **httpuv** - Local OAuth redirect URI server
- **lintr** - Code style linting
- **pkgdown** - Documentation site generation

## Architecture and Design Patterns

### Object-Oriented Design (R6 Classes)

The package uses R6 classes for an object-oriented credential system:

```
Credential (base class)
├── ClientSecretCredential
├── AzureCLICredential
└── InteractiveCredential (base for user-facing flows)
    ├── DeviceCodeCredential
    └── AuthCodeCredential
```

**Key Class: `Credential` (R/credential.R:1)**
- Base R6 class with common authentication logic
- Properties: `.scope`, `.tenant_id`, `.client_id`, `.use_cache`, etc.
- Methods: `get_token()`, `is_interactive()`, `print()`

**Credential Chain Pattern:**
The package sequentially tries different credential types until one succeeds, similar to Python's `DefaultAzureCredential`.

### Configuration Management

**Environment Variable Discovery:**
- `AZURE_CLIENT_ID` - Azure application (client) ID
- `AZURE_CLIENT_SECRET` - Client secret for service principal
- `AZURE_TENANT_ID` - Azure AD tenant ID
- `AZURE_AUTHORITY_HOST` - Azure cloud endpoint (public, government, china)

**Default Values:**
- Default client ID: `04b07795-8ddb-461a-bbee-02f9e1bf7b46` (Microsoft's public Azure CLI client)
- Default tenant: `common` (multi-tenant)
- Default scope: `https://management.azure.com/.default` (Azure Resource Manager)

**Predefined Scopes (R/constants.R:31):**
- `azure_arm` - Azure Resource Manager
- `azure_graph` - Microsoft Graph API
- `azure_storage` - Azure Storage
- `azure_key_vault` - Azure Key Vault

### Token Caching

Two caching strategies:
- **`disk`** - Persistent token cache (default)
- **`memory`** - Session-only cache

Cache key includes: client_id + tenant_id + scope + credential classname

## Public API

### Main Entry Points

**`get_token()`** (R/default-credential.R)
- Convenience function for one-time token acquisition
- Automatically discovers credentials using default chain
- Returns token object with `access_token` field

**`get_token_provider()`** (R/default-credential.R)
- Returns a function that acquires tokens (lazy evaluation)
- Useful for token refresh scenarios

**`get_request_authorizer()`** (R/default-credential.R)
- Returns a function that authorizes httr2 requests
- Most convenient for API client integration

### Credential Classes (Exported)

- `ClientSecretCredential` - Non-interactive service principal auth
- `AzureCLICredential` - Uses existing `az` CLI login
- `DeviceCodeCredential` - Device code flow (prints code + URL)
- `AuthCodeCredential` - Browser-based authorization code flow
- `InteractiveCredential` - Base class for interactive flows

### Configuration Helpers (Exported)

- `default_azure_client_id()` - Get/discover client ID
- `default_azure_client_secret()` - Get/discover client secret
- `default_azure_tenant_id()` - Get/discover tenant ID
- `default_azure_scope()` - Get scope URL for resource
- `default_azure_host()` - Get Azure authority host
- `default_azure_url()` - Build OAuth URLs
- `default_redirect_uri()` - Build redirect URI

## Development Workflow

### Code Style Guidelines

**Naming Conventions** (.lintr:2-4):
- **Functions/variables:** `snake_case` (preferred)
- **R6 classes:** `CamelCase`
- **Constants:** `UPPERCASE`
- **Symbols:** Allowed

**Line Length:** 120 characters maximum

**Encoding:** UTF-8

**Linting:** Uses `lintr` package with default linters plus:
- `line_length_linter(120L)`
- Flexible `object_name_linter` (snake_case, CamelCase, UPPERCASE, symbols)
- `object_usage_linter` disabled

### Documentation Standards

**Roxygen2** (RoxygenNote: 7.3.3):
- All exported functions must have roxygen2 documentation
- Use markdown format in documentation
- Include `@param`, `@return`, `@examples`, `@export` tags
- Examples should be wrapped in `\dontrun{}` if they require credentials

**Documentation Generation:**
```r
# Generate documentation
devtools::document()

# Build pkgdown site
pkgdown::build_site()
```

### Testing and Quality Assurance

**No Unit Tests Currently:**
- The repository has `Config/testthat/edition: 3` in DESCRIPTION
- But no test files exist yet (`.Rbuildignore` excludes `^tests$`)
- Testing relies on R CMD CHECK validation

**CI/CD Pipeline:**

**1. R CMD Check** (.github/workflows/R-CMD-check.yaml):
- Runs on: macOS, Windows, Ubuntu (devel, release, oldrel-1)
- Cross-platform validation
- Triggered on: push to main/master, pull requests

**2. Linting** (.github/workflows/lint.yaml):
- Runs `lintr::lint_package()`
- Environment: `LINTR_ERROR_ON_LINT=true` (fails on lint errors)
- Triggered on: push to main/master, pull requests

**3. Documentation** (.github/workflows/pkgdown.yaml):
- Generates pkgdown documentation site
- Deploys to GitHub Pages
- URL: https://pedrobtz.github.io/azr

**4. PR Commands** (.github/workflows/pr-commands.yaml):
- Automates common PR tasks

### Building and Checking

**Local Development:**
```r
# Load package for development
devtools::load_all()

# Run R CMD check
devtools::check()

# Run linter
lintr::lint_package()

# Build documentation
devtools::document()

# Install package
devtools::install()
```

**Build Exclusions** (.Rbuildignore):
- `.Rproj.user`
- `LICENSE.md` (kept separate from LICENSE)
- `.github/` (workflows)
- `codecov.yml`
- All hidden files (`.gitignore`, `.lintr`, etc.)
- `^tests$` (currently excluded)
- `^docs$` (generated documentation)
- `cran-comments.md` and `CRAN-SUBMISSION`

## Common Development Tasks

### Adding a New Credential Type

1. Create new file: `R/credential-{name}.R`
2. Define R6 class inheriting from `Credential` or `InteractiveCredential`
3. Override `get_token()` method with authentication logic
4. Add roxygen2 documentation with `@export`
5. Update `default-credential.R` to include in default chain if applicable
6. Run `devtools::document()` to generate man pages
7. Run `devtools::check()` to validate

### Modifying the Credential Chain

The default chain is defined in `R/default-credential.R`:
```r
default_chain <- list(
  ClientSecretCredential,
  AzureCLICredential,
  DeviceCodeCredential,
  AuthCodeCredential
)
```

To modify, edit this list and ensure proper ordering (non-interactive first).

### Adding New Azure Scopes

Edit `R/constants.R` to add new predefined scopes:
```r
azure_scopes <- list(
  azure_arm = "https://management.azure.com/.default",
  azure_graph = "https://graph.microsoft.com/.default",
  # Add new scope here
  new_service = "https://service.azure.com/.default"
)
```

### Updating Environment Variables

Edit `R/constants.R` to add new environment variables:
```r
environment_variables <- list(
  azure_client_id = "AZURE_CLIENT_ID",
  # Add new variable here
)
```

## Key Code Patterns

### Error Handling

The package uses `cli` for user-friendly error messages:
```r
cli::cli_abort("Error message with {.var variable} and {.cls ClassName}")
cli::cli_alert_info("Informational message")
cli::cli_alert_warning("Warning message")
```

### Null Coalescing

Uses `%||%` operator for default values:
```r
client_id <- provided_client_id %||% default_azure_client_id()
```

### Interactive Session Detection

```r
if (!rlang::is_interactive() && self$is_interactive()) {
  cli::cli_abort("Credential {.cls {class(self)[[1]]}} requires an interactive session")
}
```

### Credential Redaction

Sensitive credentials are redacted in print output:
```r
redact_credential <- function(credential, width = 8) {
  # Redacts all but first 'width' characters
}
```

## Git Workflow

**Main Branch:** `main` (or `master`)

**Current Branch:** `claude/claude-md-mi00f4hhyjwjob1o-01Piw36ePBdYm1i41jMqbMBU`

**Commit Message Style:**
Look at recent commits for the style:
```bash
git log --oneline -10
```

Recent commits use concise messages like:
- "fix issues"
- "re-submission"
- "edit small"

**Development Branches:**
- All Claude development should use branches starting with `claude/`
- Push to the designated branch with `git push -u origin <branch-name>`

## CRAN Submission

**Status:** Initial CRAN submission (v0.1.0)

**CRAN Comments:** See `cran-comments.md` for submission notes

**CRAN Requirements:**
- R CMD CHECK must pass with no errors, warnings, or notes
- Documentation must be complete
- Examples must run without errors
- License must be specified correctly

## Important Files Reference

| File | Purpose | Key Info |
|------|---------|----------|
| `DESCRIPTION` | Package metadata | Version, dependencies, URLs |
| `NAMESPACE` | Exported functions | Auto-generated by roxygen2 |
| `R/credential.R:1` | Base Credential class | R6 class definition |
| `R/default-credential.R:46` | `get_token_provider()` | Main API entry point |
| `R/constants.R:8` | Azure defaults | Default client ID, scopes, env vars |
| `R/defaults.R` | Configuration helpers | Default value discovery |
| `.lintr` | Code style rules | Line length, naming conventions |
| `_pkgdown.yml` | Documentation site | Bootstrap 5 theme |
| `.Rbuildignore` | Build exclusions | Files to skip in R package build |

## Best Practices for AI Assistants

### When Making Changes

1. **Always run roxygen2 after editing R files:**
   ```r
   devtools::document()
   ```

2. **Check code style with lintr:**
   ```r
   lintr::lint_package()
   ```

3. **Validate changes with R CMD check:**
   ```r
   devtools::check()
   ```

4. **Test interactively:**
   ```r
   devtools::load_all()
   # Test your changes
   ```

### Code Style Preferences

- Use `snake_case` for function and variable names
- Use `CamelCase` for R6 class names
- Maximum line length: 120 characters
- Use roxygen2 markdown format for documentation
- Include `@examples` in documentation (wrap in `\dontrun{}` if needed)
- Use `cli::cli_abort()` for errors, not `stop()`
- Use `%||%` for default values, not `if (is.null(x))`

### Security Considerations

- Never commit credentials or secrets
- Always redact sensitive information in print/log output
- Validate tenant IDs and scopes
- Use environment variables for configuration
- Check interactive session status before prompting user

### Documentation Requirements

- All exported functions need roxygen2 documentation
- Include parameter descriptions (`@param`)
- Include return value descriptions (`@return`)
- Add usage examples (`@examples`)
- Link to related functions (`@seealso`)
- Use markdown formatting in roxygen2 blocks
- Reference Azure documentation URLs where applicable

### Common Pitfalls to Avoid

1. **Don't modify NAMESPACE directly** - It's auto-generated by roxygen2
2. **Don't commit `.Rproj.user/`** - It's user-specific
3. **Don't skip roxygen2 documentation** - Required for exports
4. **Don't use base R errors** - Use `cli::cli_abort()` instead
5. **Don't hardcode credentials** - Use environment variables
6. **Don't break the credential chain pattern** - Maintain sequential fallback
7. **Don't add tests without removing from .Rbuildignore** - Currently excluded

## Package URLs

- **GitHub:** https://github.com/pedrobtz/azr
- **Documentation:** https://pedrobtz.github.io/azr/
- **Issues:** https://github.com/pedrobtz/azr/issues

## Related Resources

- **httr2 OAuth:** https://httr2.r-lib.org/articles/oauth.html
- **Azure Identity (Python):** https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme
- **AzureAuth (R):** https://github.com/Azure/AzureAuth
- **R Packages Book:** https://r-pkgs.org/
- **Roxygen2 Documentation:** https://roxygen2.r-lib.org/

---

*Last Updated: 2025-11-15*
*Package Version: 0.1.0*
*This file is intended for AI assistants working on the azr package codebase.*
