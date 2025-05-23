# GCP Cloud CDN Static Website Module

This Terraform module creates a complete static website hosting solution on Google Cloud Platform (GCP) using Cloud Storage and Cloud CDN, similar to the AWS S3 + CloudFront setup. It provides a secure, scalable, and high-performance way to serve static content with custom domain support.

## Features

- 🚀 Cloud Storage bucket for static website hosting
- 🌐 Cloud CDN integration for global content delivery
- 🔒 Custom domain support with SSL/TLS
- 📝 Configurable error pages and main page suffix
- 🔄 Path-based routing rules
- 📊 Optional logging configuration
- 🔐 Service account management
- ⚡ Custom CDN policies and caching rules
- 🛡️ Custom error response handling

## Prerequisites

- Google Cloud Platform account
- Terraform >= 0.13.0
- Google Cloud SDK installed and configured
- Domain name (if using custom domain)

## Usage

```hcl
module "static_website" {
  source = "path/to/module"

  project_id    = "your-project-id"
  bucket_name   = "your-bucket-name"
  cdn_enabled   = true
  custom_domain = "example.com"
  location      = "US"
  
  # Optional configurations
  enable_logging = true
  main_page_suffix = "index.html"
  not_found_page  = "404.html"
  
  cdn_policy = {
    signed_url_cache_max_age_sec = 3600
    serve_while_stale           = 86400
    negative_caching            = true
    max_ttl                     = 86400
    default_ttl                 = 3600
    client_ttl                  = 3600
    cache_mode                  = "CACHE_ALL_STATIC"
  }
}
```

## Complete Example Configuration

Here's a complete example configuration using `terraform.tfvars`:

```hcl
# Basic Configuration
location                = "EU"  # or "US"
cdn_enabled            = true
enable_logging         = false
project_id             = "your-project-id"
bucket_name            = "your-website-name"
region                 = "europe-west4"  # or "us-central1"

# Website Configuration
not_found_page         = "index.html"
main_page_suffix       = "index.html"
network_endpoint_name  = "website-name"
cdn_service_account_name = "website-name-cdn"

# Domain Configuration
custom_domain          = "website.yourdomain.com"
fqdn_domain           = "website-name.storage.googleapis.com"

# Load Balancing Configuration
load_balancing_scheme  = "EXTERNAL_MANAGED"
http_forwarding_rule_load_balancing_scheme  = "EXTERNAL_MANAGED"
https_forwarding_rule_load_balancing_scheme = "EXTERNAL_MANAGED"

# CDN Path Rules
cdn_path_rules = [
  {
    paths               = ["/"]
    path_prefix_rewrite = "/index.html"
  }
]

# CDN Policy Configuration
cdn_policy = {
  signed_url_cache_max_age_sec = 7200
  serve_while_stale           = 86400
  negative_caching            = true
  max_ttl                     = 300
  default_ttl                 = 60
  client_ttl                  = 60
  cache_mode                  = "CACHE_ALL_STATIC"
}

# Error Response Configuration
custom_error_response_policy = {
  match_response_codes   = ["4xx", "5xx"]
  path                   = "/index.html"
  override_response_code = "0"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The ID of the GCP project | `string` | n/a | yes |
| bucket_name | The name of the GCS bucket for the static website | `string` | n/a | yes |
| cdn_enabled | Enable Cloud CDN for the backend bucket | `bool` | `true` | no |
| enable_logging | Enable logging for the backend bucket | `bool` | `false` | no |
| custom_domain | Custom domain name for the static website | `string` | `""` | no |
| cdn_service_account_name | Name of the service account used for CDN and Storage Bucket | `string` | n/a | yes |
| location | Location of the bucket | `string` | n/a | yes |
| main_page_suffix | Main page file suffix | `string` | n/a | yes |
| not_found_page | 404 page file | `string` | n/a | yes |
| cdn_path_rules | List of path rules for CDN | `list(object)` | n/a | yes |
| cdn_policy | CDN policy configuration | `object` | n/a | yes |

## Outputs

The module provides the following outputs:

- `bucket_url`: The URL of the Cloud Storage bucket
- `cdn_ip`: The IP address of the Cloud CDN
- `custom_domain_url`: The custom domain URL (if configured)

## Security

- The module creates a dedicated service account for CDN and Storage operations
- Supports SSL/TLS for custom domains
- Implements secure CDN policies and caching rules

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For support, please open an issue in the GitHub repository.