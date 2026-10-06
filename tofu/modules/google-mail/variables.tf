variable "zone" {
  description = "OVH DNS zone (e.g. afges.org)"
  type        = string
}

variable "subdomain" {
  description = "Mail domain relative to the zone, \"\" for the apex"
  type        = string
  default     = ""
}

variable "spf_includes" {
  description = "SPF include: domains, in order"
  type        = list(string)
  default     = ["_spf.google.com"]
}

variable "dkim_google" {
  description = "Google DKIM record value (v=DKIM1; k=rsa; p=...), null to skip"
  type        = string
  default     = null
}

variable "dmarc" {
  description = "DMARC record value, null to skip"
  type        = string
  default     = "v=DMARC1; p=quarantine; rua=mailto:dmarc@afges.org"
}

variable "bimi_logo" {
  description = "BIMI logo SVG URL, null to skip"
  type        = string
  default     = "https://afges.org/wp-content/uploads/2023/11/afges.svg"
}
