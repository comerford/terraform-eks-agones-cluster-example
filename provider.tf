  provider "aws" {
    version = ">= 2.28.1"
    # using the credentials file
    profile = "example"
    region = var.aws_region
}