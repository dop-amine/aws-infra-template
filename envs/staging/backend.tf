terraform {
  backend "s3" {
    bucket = "tf-state"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
}
