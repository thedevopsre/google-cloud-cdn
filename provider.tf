terraform {

  required_version = ">= 1.7.3"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.15.0, < 6.30.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.15.0, < 6.30.0"
    }
  }

  backend "gcs" {
    bucket = "bucket-name"
    prefix = "cloud-cdn/website-name"
  }
}
