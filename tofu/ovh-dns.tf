# ---------------------------------------------------------------------------
# IP records
# ---------------------------------------------------------------------------
resource "ovh_domain_zone_record" "a_root" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "A"
  target    = "40.79.130.129"
}

resource "ovh_domain_zone_record" "aaaa_root" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "AAAA"
  target    = "2603:1020:805:2::60f"
}

# ---------------------------------------------------------------------------
# Verification TXT records
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_record" "txt_anthropic_verification" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "anthropic-domain-verification-w6q770=tjgTmy2KvGczoBlEuCh2t4SYQ"
}

# For EntraID
resource "ovh_domain_zone_record" "txt_saml_direct_fed_auth" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "directFedAuthUrl=https://accounts.google.com/o/saml2/idp?idpid=C04bvk0di"
}

# Google Postmaster Tools
resource "ovh_domain_zone_record" "txt_google_postmaster_tools_verification" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "google-site-verification=6A6lN41EZRFkS_EzEwVB6Z2SStNLKb7E3kWeGzGBK6Y"
}

# Google search console
resource "ovh_domain_zone_record" "txt_google_search_console_verification" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "google-site-verification=gN2eLRx-PE5ycxuJOxpMcFV0Wonx_tTRleT4Xug0q1U"
}

# Microsoft Office 365 verification
resource "ovh_domain_zone_record" "txt_ms_verification" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "MS=ms83012819"
}

# Azure root domain verification
resource "ovh_domain_zone_record" "txt_asuid" {
  zone      = "afges.org"
  subdomain = "asuid"
  fieldtype = "TXT"
  target    = "17FEDB937FE78B69894BD5A27286E9EEF5830AF7365A134287D9A6D4913904EB"
}

# Azure internal verification
resource "ovh_domain_zone_record" "txt_asuid_interne" {
  zone      = "afges.org"
  subdomain = "asuid.interne"
  fieldtype = "TXT"
  target    = "17FEDB937FE78B69894BD5A27286E9EEF5830AF7365A134287D9A6D4913904EB"
}

# Azure www verification
resource "ovh_domain_zone_record" "txt_asuid_www" {
  zone      = "afges.org"
  subdomain = "asuid.www"
  fieldtype = "TXT"
  target    = "17FEDB937FE78B69894BD5A27286E9EEF5830AF7365A134287D9A6D4913904EB"
}

# ---------------------------------------------------------------------------
# Mail records (MX target = "<priority> <host>.")
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_record" "mx_1" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "MX"
  target    = "10 aspmx3.googlemail.com."
}

resource "ovh_domain_zone_record" "mx_2" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "MX"
  target    = "10 aspmx2.googlemail.com."
}

resource "ovh_domain_zone_record" "mx_3" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "MX"
  target    = "5 alt2.aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "mx_4" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "MX"
  target    = "5 alt1.aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "mx_5" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "MX"
  target    = "1 aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "txt_bimi_default" {
  zone      = "afges.org"
  subdomain = "default._bimi"
  fieldtype = "TXT"
  target    = "v=BIMI1;l=https://afges.org/wp-content/uploads/2023/11/afges.svg"
}

resource "ovh_domain_zone_record" "txt_dmarc" {
  zone      = "afges.org"
  subdomain = "_dmarc"
  fieldtype = "TXT"
  target    = "v=DMARC1; p=quarantine; rua=mailto:2b72d1dd6a5a423d9337802d1c63ad3b@dmarc-reports.cloudflare.net,mailto:dmarc@afges.org"
}

resource "ovh_domain_zone_record" "txt_dkim_google" {
  zone      = "afges.org"
  subdomain = "google._domainkey"
  fieldtype = "TXT"
  target    = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArYZzUGpjFdwV2DlR8DsyDgQsM2C3DyNL9FY0ZMv69zqsCN8RApk321xRBBvILBG0BnVo9Oun0WLmkacPGowt6FUBkDGq2jf7Y0GsnYJNoZdbkZjjNidBx/48n9OXSrSFw+WHo1j4MjQBmTb5Cprbc2KMYOWNeMK5kS0BFOUxYHxDHCDXoixTKCnlUU2WLpXFdpip9GJ5NsKYiRTxBIWBUaUB77cfFyMnzVYjDLYYcqTgt8sutZihpH78ZGlExQXvLdE795T5GB8wlidMl7Q7tw+Kxd7fryjAQxXyYFFU900xm7iOY2vT1ceusmS0nT90aevk/RHK3kib9CwZ0yPzCQIDAQAB"
}

resource "ovh_domain_zone_record" "txt_spf" {
  zone      = "afges.org"
  subdomain = ""
  fieldtype = "TXT"
  target    = "v=spf1 include:spf.mailjet.com include:_spf.google.com include:mailway.app ~all"
}

resource "ovh_domain_zone_record" "txt_dkim_mailjet" {
  zone      = "afges.org"
  subdomain = "mailjet._domainkey"
  fieldtype = "TXT"
  target    = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcUIBlM/c77n76OFJdb1Un19GeOTKEmD1t0LIQbtQjdTyVGdT9KailLoB93bem4U8NTEDwt8jYvy7R9cs/6ii9uHX5IFEMq4T4PgEMyJ3Af1vcrb+rheINJ6mxcURiAXHaKSyWaSBhXSUrSEbJQflNUJgakwSe93NbfUYuZFybIwIDAQAB"
}

# Mailjet managed by AFGES
resource "ovh_domain_zone_record" "txt_mailjet_afges_verification" {
  zone      = "afges.org"
  subdomain = "mailjet._e6c3b5ba"
  fieldtype = "TXT"
  target    = "e6c3b5ba4caee4d415c54c791fdcdcdb"
}

# Mailjet managed by Eudonet/Fdus
resource "ovh_domain_zone_record" "txt_mailjet_fdus_verification" {
  zone      = "afges.org"
  subdomain = "mailjet._ebd46c50"
  fieldtype = "TXT"
  target    = "ebd46c508d582daff068bb807e15a5ef"
}

# ---------------------------------------------------------------------------
# Redirections
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_redirection" "redirect_ctc" {
  zone      = "afges.org"
  subdomain = "ctc"
  type      = "visiblePermanent" # 301 redirect
  target    = "https://changetoncampus.afges.org"
}

resource "ovh_domain_zone_redirection" "redirect_discord" {
  zone      = "afges.org"
  subdomain = "discord"
  type      = "visiblePermanent" # 301 redirect
  target    = "https://discord.gg/axjndna"
}

# ---------------------------------------------------------------------------
# CNAME records
# ---------------------------------------------------------------------------

# AIUS
resource "ovh_domain_zone_record" "cname_changetoncampus" {
  zone      = "afges.org"
  subdomain = "changetoncampus"
  fieldtype = "CNAME"
  target    = "changetoncampus.aius.u-strasbg.fr."
}

resource "ovh_domain_zone_record" "cname_changetoncrous" {
  zone      = "afges.org"
  subdomain = "changetoncrous"
  fieldtype = "CNAME"
  target    = "changetoncampus.aius.u-strasbg.fr."
}

# Azure static web app
resource "ovh_domain_zone_record" "cname_ctc23" {
  zone      = "afges.org"
  subdomain = "ctc23"
  fieldtype = "CNAME"
  target    = "gentle-hill-0ac869203.4.azurestaticapps.net."
}

# Azure WordPress
resource "ovh_domain_zone_record" "cname_interne" {
  zone      = "afges.org"
  subdomain = "interne"
  fieldtype = "CNAME"
  target    = "afges.azurewebsites.net."
}

resource "ovh_domain_zone_record" "cname_www" {
  zone      = "afges.org"
  subdomain = "www"
  fieldtype = "CNAME"
  target    = "afges.azurewebsites.net."
}

# Google Sites
resource "ovh_domain_zone_record" "cname_dlp" {
  zone      = "afges.org"
  subdomain = "dlp"
  fieldtype = "CNAME"
  target    = "ghs.googlehosted.com."
}

resource "ovh_domain_zone_record" "cname_ukraine" {
  zone      = "afges.org"
  subdomain = "ukraine"
  fieldtype = "CNAME"
  target    = "ghs.googlehosted.com."
}

# GitHub Pages
resource "ovh_domain_zone_record" "cname_droit_local" {
  zone      = "afges.org"
  subdomain = "droit-local"
  fieldtype = "CNAME"
  target    = "afges.github.io."
}

# Microsoft
resource "ovh_domain_zone_record" "cname_enterpriseenrollment" {
  zone      = "afges.org"
  subdomain = "enterpriseenrollment"
  fieldtype = "CNAME"
  target    = "enterpriseenrollment-s.manage.microsoft.com."
}

resource "ovh_domain_zone_record" "cname_enterpriseregistration" {
  zone      = "afges.org"
  subdomain = "enterpriseregistration"
  fieldtype = "CNAME"
  target    = "enterpriseregistration.windows.net."
}

# ---------------------------------------------------------------------------
# "anciens" subdomain: MX + SPF
# ---------------------------------------------------------------------------

resource "ovh_domain_zone_record" "mx_anciens_1" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "MX"
  target    = "10 aspmx3.googlemail.com."
}

resource "ovh_domain_zone_record" "mx_anciens_2" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "MX"
  target    = "10 aspmx2.googlemail.com."
}

resource "ovh_domain_zone_record" "mx_anciens_3" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "MX"
  target    = "5 alt2.aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "mx_anciens_4" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "MX"
  target    = "5 alt1.aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "mx_anciens_5" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "MX"
  target    = "1 aspmx.l.google.com."
}

resource "ovh_domain_zone_record" "txt_anciens_spf" {
  zone      = "afges.org"
  subdomain = "anciens"
  fieldtype = "TXT"
  target    = "v=spf1 include:_spf.google.com ~all"
}
