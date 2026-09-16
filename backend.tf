# Replace the bucket name after running terraform/bootstrap.
terraform {
  backend "s3" {
    bucket       = "octabyte-devops-tfstate-c969f900"
    key          = "octabyte/devops/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
