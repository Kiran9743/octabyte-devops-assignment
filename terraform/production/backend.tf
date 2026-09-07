terraform {
  backend "s3" {
    bucket         = "octabyte-devops-tfstate-c969f900"
    key            = "production/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
