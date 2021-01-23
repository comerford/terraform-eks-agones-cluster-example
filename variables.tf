variable "aws_region" {
    default = "eu-west-1"
}
#TODO - move more of these actual values into terraform.tfvars
variable "cluster_name" {
  default = "example-k8s-cluster"
}
# Agones module variables - first install was on 1.7.0
variable "agones_version" {
  default = "1.10.0"
}

variable "log_level" {
  default = "info"
}

variable "feature_gates" {
  default = "PlayerTracking=true&ContainerPortAllocation=true"
}
# End Agones module vars

variable "managed_tags" {
    default = {
        managed_by = "Terraform"
        repo_name = "terraform-eks-agones-cluster-example"
    }
}
variable vpc_azs {
    default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "aws_account_id" {}

variable "autoscaling_tags" {
    default = [
      {
        "key" = "k8s.io/cluster-autoscaler/example-k8s-cluster"
        "propagate_at_launch" = "false"
        "value" = "true"
       },
      {
        "key" = "k8s.io/cluster-autoscaler/enabled"
        "propagate_at_launch" = "false"
        "value" = "true"
      },
    ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

}
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}