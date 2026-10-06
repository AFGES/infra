# ---------------------------------------------------------------------------
# Redirections to afges.org
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_redirection" "fr_redirect_root" {
  zone      = "afges.fr"
  subdomain = ""
  type      = "visiblePermanent" # 301 redirect
  target    = "https://afges.org"
}

resource "ovh_domain_zone_redirection" "fr_redirect_www" {
  zone      = "afges.fr"
  subdomain = "www"
  type      = "visiblePermanent" # 301 redirect
  target    = "https://afges.org"
}

resource "ovh_domain_zone_redirection" "fr_redirect_redirect" {
  zone      = "afges.fr"
  subdomain = "redirect"
  type      = "visiblePermanent" # 301 redirect
  target    = "https://afges.org"
}

# ---------------------------------------------------------------------------
# Verification TXT records
# ---------------------------------------------------------------------------

# Google Workspace
resource "ovh_domain_zone_record" "fr_txt_google_workspace_verification" {
  zone      = "afges.fr"
  subdomain = ""
  fieldtype = "TXT"
  target    = "google-site-verification=O-fXWwAT7MYXZ-paqX6YDdWnYft7L-hPT5alFCPfafE"
}

# ---------------------------------------------------------------------------
# Mail (Google Workspace)
# ---------------------------------------------------------------------------

module "mail_afges_fr" {
  source = "./modules/google-mail"

  zone        = "afges.fr"
  dkim_google = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwXGpCu/l3SWhOBMtMp5OkQCEEHAMZ3iy2HJE7caYG2iQ5T2qBatD8moA1+2a/1CmDlUrFjqXxVe7OncQ62qIMd5b8f5ifX5kEOQgKDMc6xSX6FCBcXQW68eFuu9rd6yVV+cBkST1L1I1AlHNC+KjkTE40sTwGKyMjwM8PUmaXk36eADNVjZm4l5PXqBoCWSt+mCgNn9lN9uzhp9H/6hAe4R1zoULRCLkoaji2d/uMsc5iWWJMGc1+vgde3y3B2dP2LjTtlKSYI042BmZKKMJc0tFtvMLoU8d8znWgb1l9oBLtqW7ycjXtHxpdITSifEnm6B8UF8IhbY5b/tDxhrPNwIDAQAB"
}
