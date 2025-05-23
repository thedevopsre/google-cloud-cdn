variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "bucket_name" {
  description = "The name of the GCS bucket for the static website."
  type        = string
}

variable "cdn_enabled" {
  description = "Enable Cloud CDN for the backend bucket."
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging for the backend bucket."
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain name for the static website."
  type        = string
  default     = ""
}

variable "cdn_service_account_name" {
  description = "Name of the service account used for CDN and Storage Bucket."
  type        = string
}

variable "location" {
  description = "Location of the bucket."
  type        = string
}

variable "fqdn_domain" {
  description = "The bucket API URL."
  type        = string
}

variable "network_endpoint_name" {
  description = "The name of the network endpoint."
  type        = string
}

variable "not_found_page" {
  description = "not-found page file."
  type        = string
}

variable "main_page_suffix" {
  description = "Main part to page file."
  type        = string
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme."
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "cdn_path_rules" {
  type = list(object({
    paths               = list(string)
    path_prefix_rewrite = string
  }))
  description = "List of path rules for CDN"
}

variable "cdn_policy" {
  type = object({
    signed_url_cache_max_age_sec = number
    serve_while_stale            = number
    negative_caching             = bool
    max_ttl                      = number
    default_ttl                  = number
    client_ttl                   = number
    cache_mode                   = string
  })
  description = "CDN policy configuration for backend service"
}

variable "http_forwarding_rule_load_balancing_scheme" {
  description = "Load balancing scheme for the HTTP forwarding rule."
  type        = string
}

variable "https_forwarding_rule_load_balancing_scheme" {
  description = "Load balancing scheme for the HTTPS forwarding rule."
  type        = string
}

variable "custom_error_response_policy" {
  description = "Configuration for custom error response policy"
  type = object({
    match_response_codes   = list(string)
    path                   = string
    override_response_code = string
  })
  default = {
    match_response_codes   = ["4xx", "5xx"]
    path                   = "/index.html"
    override_response_code = "0"
  }
}
