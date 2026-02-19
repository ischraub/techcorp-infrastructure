terraform {
  backend "s3" {
    bucket       = "techcorp-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
