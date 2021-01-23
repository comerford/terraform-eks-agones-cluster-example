# this sets up the VPC which the kubernetes cluster will run in, playing very conservative with ranges
# until we have a proper idea of sizing
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.39.0"

  name                 = "k8s-${aws_region}-vpc"
  cidr                 = "198.51.100.0/24"
  azs                  = var.vpc_azs
  # most things will be going into the private subnets, and this will cover ~3000 IPs
  private_subnets = ["198.51.100.0/27", "198.51.100.32/27", "198.51.100.64/27"]
  # public subnets would have to be explicitly specified by workers
  public_subnets =  ["198.51.100.128/27", "198.51.100.160/27", "198.51.100.192/27"]
  enable_nat_gateway   = true # would be false in prod
  single_nat_gateway   = true # again false in prod
  enable_dns_hostnames = true
  
  # if you attempt to put a reference to the EKS cluster in here you 
  # create a cyclical reference error, so locals used instead
  tags =  merge({
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }, var.managed_tags)


  public_subnet_tags = {
    "Name"                                        = "${local.cluster_name}-eks-public"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "Name"                                        = "${local.cluster_name}-eks-private"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}