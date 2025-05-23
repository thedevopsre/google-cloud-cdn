resource "google_compute_global_address" "static_ip" {
  name    = "${var.bucket_name}-cdn-static-ip"
  project = var.project_id
}

resource "google_storage_bucket" "static_website" {
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  public_access_prevention    = "enforced"
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.location

  cors {
    max_age_seconds = 3600
    method = [
      "GET",
    ]
    origin = [
      "*",
    ]
    response_header = [
      "*",
    ]
  }

  website {
    not_found_page   = var.not_found_page
    main_page_suffix = var.main_page_suffix
  }
}

resource "google_service_account" "cdn_service_account" {
  project      = var.project_id
  display_name = "Cloud CDN Service Account"
  account_id   = var.cdn_service_account_name
}

resource "google_storage_hmac_key" "key" {
  service_account_email = google_service_account.cdn_service_account.email
  project               = var.project_id
}

resource "google_storage_bucket_iam_member" "cdn_object_viewer" {
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.cdn_service_account.account_id}@${var.project_id}.iam.gserviceaccount.com"
  bucket = google_storage_bucket.static_website.name
}

resource "google_compute_global_network_endpoint_group" "neg" {
  project               = var.project_id
  network_endpoint_type = "INTERNET_FQDN_PORT"
  name                  = var.network_endpoint_name
  default_port          = 80
}

resource "google_compute_global_network_endpoint" "neg_endpoint" {
  project                       = var.project_id
  port                          = 80
  global_network_endpoint_group = google_compute_global_network_endpoint_group.neg.name
  fqdn                          = "${var.bucket_name}.storage.googleapis.com"
}

resource "google_compute_backend_service" "backend_service" {
  timeout_sec                     = 10
  protocol                        = "HTTP"
  project                         = var.project_id
  port_name                       = "port-name"
  name                            = "${var.bucket_name}-backend-service"
  load_balancing_scheme           = var.load_balancing_scheme
  enable_cdn                      = true
  connection_draining_timeout_sec = 300
  compression_mode                = "AUTOMATIC"

  backend {
    group           = google_compute_global_network_endpoint_group.neg.id
    capacity_scaler = 1
    balancing_mode  = "UTILIZATION"
  }

  dynamic "cdn_policy" {
    for_each = var.cdn_policy != null ? [var.cdn_policy] : []
    content {
      signed_url_cache_max_age_sec = cdn_policy.value.signed_url_cache_max_age_sec
      serve_while_stale            = cdn_policy.value.serve_while_stale
      negative_caching             = cdn_policy.value.negative_caching
      max_ttl                      = cdn_policy.value.max_ttl
      default_ttl                  = cdn_policy.value.default_ttl
      client_ttl                   = cdn_policy.value.client_ttl
      cache_mode                   = cdn_policy.value.cache_mode
    }
  }

  custom_request_headers = [
    "host: ${var.bucket_name}.storage.googleapis.com",
  ]

  security_settings {
    aws_v4_authentication {
      origin_region = var.region
      access_key    = google_storage_hmac_key.key.secret
      access_key_id = google_storage_hmac_key.key.access_id
    }
  }

  depends_on = [
    google_storage_hmac_key.key,
    google_storage_bucket.static_website,
  ]
}

resource "google_compute_url_map" "url_map" {
  project  = var.project_id
  name     = "${var.bucket_name}-url-map"
  provider = google-beta

  default_service = google_compute_backend_service.backend_service.id

  default_custom_error_response_policy {
    error_response_rule {
      match_response_codes   = var.custom_error_response_policy.match_response_codes
      path                   = var.custom_error_response_policy.path
      override_response_code = var.custom_error_response_policy.override_response_code
    }
    error_service = google_compute_backend_service.backend_service.id
  }

  host_rule {
    hosts        = [var.custom_domain]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.backend_service.id

    default_custom_error_response_policy {
      error_response_rule {
        match_response_codes   = var.custom_error_response_policy.match_response_codes
        path                   = var.custom_error_response_policy.path
        override_response_code = var.custom_error_response_policy.override_response_code
      }
      error_service = google_compute_backend_service.backend_service.id
    }

    dynamic "path_rule" {
      for_each = var.cdn_path_rules
      content {
        paths   = path_rule.value.paths
        service = google_compute_backend_service.backend_service.id

        route_action {
          url_rewrite {
            path_prefix_rewrite = path_rule.value.path_prefix_rewrite
          }
        }
      }
    }
  }
}

resource "google_compute_url_map" "http_redirect_url_map" {
  project = var.project_id
  name    = "${var.bucket_name}-http-redirect-url-map"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    https_redirect         = true
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "proxy" {
  url_map = google_compute_url_map.url_map.id
  project = var.project_id
  name    = "${var.bucket_name}-http-proxy"
}

resource "google_compute_target_http_proxy" "http_redirect_proxy" {
  project = var.project_id
  name    = "${var.bucket_name}-http-redirect-proxy"
  url_map = google_compute_url_map.http_redirect_url_map.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project          = var.project_id
  name             = "${var.bucket_name}-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
  url_map          = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  project               = var.project_id
  name                  = "${var.bucket_name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_redirect_proxy.id
  load_balancing_scheme = var.http_forwarding_rule_load_balancing_scheme
  port_range            = "80"
  ip_address            = google_compute_global_address.static_ip.address
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  project               = var.project_id
  name                  = "${var.bucket_name}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  load_balancing_scheme = var.https_forwarding_rule_load_balancing_scheme
  port_range            = "443"
  ip_address            = google_compute_global_address.static_ip.address
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name    = "${var.bucket_name}-ssl-cert"
  project = var.project_id

  managed {
    domains = [var.custom_domain]
  }
}
