terraform {
    backend "s3"{
        bucket = "terraform-base-configs"
        key = "terraform-eks-agones-cluster-example/terraform.tfstate"
        region = "eu-west-1"
        profile = "example"
    }
}