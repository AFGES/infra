# ---------------------------------------------------------------------------
# IP records
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_record" "eu_a_root" {
  zone      = "afges.eu"
  subdomain = ""
  fieldtype = "A"
  target    = "193.200.233.163"
}

resource "ovh_domain_zone_record" "eu_a_wildcard" {
  zone      = "afges.eu"
  subdomain = "*"
  fieldtype = "A"
  target    = "193.200.233.163"
}

# ---------------------------------------------------------------------------
# Verification TXT records
# ---------------------------------------------------------------------------

# Have I Been Pwned
resource "ovh_domain_zone_record" "eu_txt_hibp_verification" {
  zone      = "afges.eu"
  subdomain = ""
  fieldtype = "TXT"
  target    = "hibp-verify=dweb_mmytr1p0bjszcd2fi1cnf4t8"
}

# Google Workspace
resource "ovh_domain_zone_record" "eu_txt_google_workspace_verification" {
  zone      = "afges.eu"
  subdomain = ""
  fieldtype = "TXT"
  target    = "google-site-verification=WRPPLpbueJq6msA51x-AH0_x6rodGOdqnI9HG5IkEUg"
}

# ---------------------------------------------------------------------------
# Mail (Google Workspace)
# ---------------------------------------------------------------------------

module "mail_afges_eu" {
  source = "./modules/google-mail"

  zone        = "afges.eu"
  dkim_google = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnZd9clOz7L591Ldh0+V3m23XrhFIBA5cJ3BEji9BoBtwtt94S6nMqdPSa40KHfl64dQOtKq6cen/DdV0rYjw9wp6ee0VpkkLDO7mCaHX9q5J9ajk0h+zpvrUPnSqDQLEkyid8+l7SMORe4vK4ONmAH3cBez94rogos2JnsWQav0YYKZA9G2FMwsyND+PzogkEyuerRgsDYLyb+I465PZkYgYmhqEb+hr6Br9ECcst59PikC1ldLzcncZpz6sgtGDZhfRBgwZlt8H/WXFOl04lshOoJLZVYstJk+bYSiKgoSopwF8OPbdRSB7in2QcqJ98pytElKrhr5LAfn4Vb8LRwIDAQAB"
  dmarc       = "v=DMARC1; p=quarantine; rua=mailto:a12afdcac0f348fda0fc8b6a42df34ab@dmarc-reports.cloudflare.net,mailto:dmarc@afges.org"
}
