terraform {
  backend "s3" {
    bucket         = "vaultbridge-terraform-state-be47ce7b"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "vaultbridge-terraform-locks"
    encrypt        = true
  }
}
