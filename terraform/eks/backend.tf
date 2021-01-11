terraform {
  required_version = ">= 0.12.0"

  backend "s3" {
    bucket = "parcel-terraform-state"
    key    = "eks.terraform.tfstate"
    region = "ap-southeast-1"
  }
}