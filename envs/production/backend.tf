terraform {
  backend "s3" {
    bucket = "tf-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}
