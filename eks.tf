# dependencies of the EKS module per: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/12.1.0?tab=dependencies
provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_dev.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_dev.cluster_id
}

provider "helm" {
  alias = "eks-example-cluster"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
    version                = ">= 1.10"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = ">= 1.10"
}

# based on https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/basic/main.tf
module "eks_dev" {
  source       = "terraform-aws-modules/eks/aws"
  version = "12.2.0"
  cluster_name = "example-k8s-cluster"
  subnets      = module.vpc.private_subnets
  cluster_version = "1.17" #latest version supported by Agones at time of writing config
  tags = merge({ Environment = "dev", Role = "k8s-hosts"}, var.managed_tags)
  cluster_enabled_log_types = ["api", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_endpoint_private_access_cidrs = [module.vpc.vpc_cidr_block, "192.0.2.0/24 "]

  vpc_id = module.vpc.vpc_id
  # worker_group defaults - https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/local.tf#L35
  # Some potentially interesting ones:
  #     platform                      = "linux"                     # Platform of workers. either "linux" or "windows"
  #     subnets                       = var.subnets                 # A list of subnets to place the worker nodes in. i.e. ["subnet-123", "subnet-456", "subnet-789"]
  #     public_ip                     = false                       # Associate a public ip address with a worker
  #     root_volume_size              = "100"                       # root volume size of workers instances.
  #     root_volume_type              = "gp2"                       # root volume type of workers instances, can be 'standard', 'gp2', or 'io1'
  #     ami_id                        = ""                          # AMI ID for the eks linux based workers. If none is provided, Terraform will search for the latest version of their EKS optimized worker AMI based on platform.
  #     ami_id_windows                = ""                          # AMI ID for the eks windows based workers. If none is provided, Terraform will search for the latest version of their EKS optimized worker AMI based on platform.
  #     asg_desired_capacity          = "1"                         # Desired worker capacity in the autoscaling group and changing its value will not affect the autoscaling group's desired capacity because the cluster-autoscaler manages up and down scaling of the nodes. Cluster-autoscaler add nodes when pods are in pending state and remove the nodes when they are not required by modifying the desirec_capacity of the autoscaling group. Although an issue exists in which if the value of the asg_min_size is changed it modifies the value of asg_desired_capacity.
  #     asg_max_size                  = "3"                         # Maximum worker capacity in the autoscaling group.
  #     asg_min_size                  = "1"                         # Minimum worker capacity in the autoscaling group. NOTE: Change in this paramater will affect the asg_desired_capacity, like changing its value to 2 will change asg_desired_capacity value to 2 but bringing back it to 1 will not affect the asg_desired_capacity.
    


  worker_groups = [
    {
      name                          = "services-linux"
      instance_type                 = "t3.large"
      asg_min_size                  = 1
      asg_desired_capacity          = 1
      asg_max_size                  = 5
      enabled_metrics               = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingCapacity", "GroupPendingInstances", "GroupStandbyCapacity", "GroupStandbyInstances", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances",]
      additional_security_group_ids = [aws_security_group.services_wg_mgmt_one.id]
      kubelet_extra_args            = "--node-labels=role=services"
    },
    {
      name                          = "gameservers-public"
      instance_type                 = "c5a.4xlarge"
      asg_min_size                  = 1
      asg_desired_capacity          = 1
      asg_max_size                  = 5
      # per this page, need tagging to be auto-scaled:
      # https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
      tags                          = var.autoscaling_tags
      enabled_metrics               = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingCapacity", "GroupPendingInstances", "GroupStandbyCapacity", "GroupStandbyInstances", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances",]
      kubelet_extra_args            = "--node-labels=role=gameserver"
      additional_security_group_ids = [aws_security_group.services_wg_mgmt_one.id, aws_security_group.gameservers_wg_udp.id]
      subnets                       = module.vpc.public_subnets
    },
  ]
  manage_aws_auth = true
  map_users                            = var.map_users
  map_roles                            = var.map_roles


# leaving for reference 
# worker_ami_name_filter Name filter for AWS EKS worker AMI. If not provided, the latest official AMI for the specified 'cluster_version' is
# see also: worker_ami_owner_id 

# Fine grained access controls for Kubernetes (satisfy least privilege, complex)
enable_irsa                          = true
# example - https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/irsa

# worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
# map_accounts                         = var.map_accounts
}

resource "helm_release" "cluster_autoscaler" {
  # this and the alias provider/alias setting above prevents initial connection to cluster errors
  provider   = helm.eks-example-cluster

  name       = "cluster-autoscaler"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "cluster-autoscaler"
  version    = "7.3.4"
  namespace  = "kube-system"

  set {
    name  = "repository"
    value = "us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"
  }

  set {
    name  = "imageTag"
    value = "v1.16.5"
  }

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "awsRegion"
    value = "ap-northeast-2"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccountAnnotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${var.aws_account_id}:role/cluster-autoscaler-example-cluster"
    type  = "string"
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks_dev.cluster_id
  }
}