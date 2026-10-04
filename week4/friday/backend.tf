terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket                      = "kijanikiosk-iac-state"
    key                         = "production/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://localhost:9000"
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
