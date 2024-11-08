terraform {
  required_version = ">= 1.3.9"

  backend "s3" {
    # Backend configuration will be loaded from a tfvars file

  }
}