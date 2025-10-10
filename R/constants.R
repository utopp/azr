
AzureClient <- list(
  TENANT_ID = "common",
  CLIENT_ID = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
)

AzureAuthorityHosts <- list(
  AZURE_CHINA = "login.chinacloudapi.cn",
  AZURE_GOVERNMENT = "login.microsoftonline.us",
  AZURE_PUBLIC_CLOUD = "login.microsoftonline.com"
)

AzureScopes <- list(
  AZURE_ARM = "https://management.azure.com/.default",
  AZURE_GRAPH = "https://graph.microsoft.com/.default",
  AZURE_STORAGE = "https://storage.azure.com/.default"
)

EnvironmentVariables <- list(
  AZURE_CLIENT_ID = "AZURE_CLIENT_ID",
  AZURE_CLIENT_SECRET = "AZURE_CLIENT_SECRET",
  AZURE_TENANT_ID = "AZURE_TENANT_ID",
  CLIENT_SECRET_VARS = c("AZURE_CLIENT_ID", "AZURE_CLIENT_SECRET", "AZURE_TENANT_ID"),
  CERT_VARS = c("AZURE_CLIENT_ID", "AZURE_CLIENT_CERTIFICATE_PATH", "AZURE_TENANT_ID"),
  AZURE_USERNAME = "AZURE_USERNAME",
  AZURE_PASSWORD = "AZURE_PASSWORD",
  USERNAME_PASSWORD_VARS = c("AZURE_CLIENT_ID", "AZURE_USERNAME", "AZURE_PASSWORD")
)
