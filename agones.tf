# Module for setting up Agones (via Helm3)

module "helm_agones" {
  source = "git::https://github.com/googleforgames/agones.git//install/terraform/modules/helm3/?ref=master"   

  udp_expose             = "false"
  agones_version         = var.agones_version
  values_file            = ""
  chart                  = "agones"
  force_update           = false
  feature_gates          = var.feature_gates
  host                   = module.eks_dev.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(module.eks_dev.cluster_certificate_authority_data)
  log_level              = var.log_level
  gameserver_minPort     = 7000
  gameserver_maxPort     = 8000
  gameserver_namespaces  = ["default", "gameservers"]
}

