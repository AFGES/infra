# Google Workspace OIDC Authentication Realm for Proxmox VE
# Enables users to authenticate to Proxmox using their Google Workspace accounts

resource "proxmox_virtual_environment_realm_openid" "google_workspace" {
  realm      = "google"
  issuer_url = data.sops_file.secrets.data["google_workspace_oidc.issuer_url"]
  client_id  = data.sops_file.secrets.data["google_workspace_oidc.client_id"]
  client_key = data.sops_file.secrets.data["google_workspace_oidc.client_secret"]

  # Use email as the unique identifier for users
  username_claim = "subject"

  # Automatically create users when they first log in
  autocreate = true

  # Request OpenID Connect scopes
  # - openid: Required for OIDC
  # - email: Get the user's email address
  # - profile: Get the user's basic profile information
  scopes = "openid email profile"

  # Query the userinfo endpoint to get additional user claims
  # This is useful when the ID token doesn't contain all needed claims
  query_userinfo = true

  comment = "Google Workspace SSO via OpenID Connect"
}
