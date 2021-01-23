# account ID (for ARNs)
aws_account_id = "961837570417"
# user mapping for IAM users
map_users = [
    {
      userarn  = "arn:aws:iam::12345678910:user/someone"
      username = "someone"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::12345678910:user/someoneelse"
      username = "someoneelse"
      groups   = ["system:masters"]
    },
  ]
# IAM roles to map
map_roles = [
    {
      rolearn = "arn:aws:iam::12345678910:role/AutomationAgent"
      username = "AutomationAgent"
      groups = ["system:public-info-viewer"]
    },
]
# Agones version to use
agones_version = "1.11.0"