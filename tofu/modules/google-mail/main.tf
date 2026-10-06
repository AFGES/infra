locals {
  # Prefix a label (e.g. "_dmarc") with the mail subdomain, if any
  suffix = var.subdomain == "" ? "" : ".${var.subdomain}"
}

# https://knowledge.workspace.google.com/admin/domains/set-up-mx-records-for-google-workspace
resource "ovh_domain_zone_record" "mx" {
  zone      = var.zone
  subdomain = var.subdomain
  fieldtype = "MX"
  target    = "1 smtp.google.com."
}

resource "ovh_domain_zone_record" "spf" {
  zone      = var.zone
  subdomain = var.subdomain
  fieldtype = "TXT"
  target    = "v=spf1 ${join(" ", [for d in var.spf_includes : "include:${d}"])} ~all"
}

# TXT strings are limited to 255 chars: split the key into quoted chunks
resource "ovh_domain_zone_record" "dkim_google" {
  count = var.dkim_google == null ? 0 : 1

  zone      = var.zone
  subdomain = "google._domainkey${local.suffix}"
  fieldtype = "TXT"
  target    = join(" ", [for c in regexall(".{1,255}", var.dkim_google) : "\"${c}\""])
}

resource "ovh_domain_zone_record" "dmarc" {
  count = var.dmarc == null ? 0 : 1

  zone      = var.zone
  subdomain = "_dmarc${local.suffix}"
  fieldtype = "TXT"
  target    = var.dmarc
}

resource "ovh_domain_zone_record" "bimi" {
  count = var.bimi_logo == null ? 0 : 1

  zone      = var.zone
  subdomain = "default._bimi${local.suffix}"
  fieldtype = "TXT"
  target    = "v=BIMI1;l=${var.bimi_logo}"
}
