# Begin rules - services worker group one
resource "aws_security_group" "services_wg_mgmt_one" {
  name_prefix = "services_wg_mgmt_one"
  description = "manage access to services worker group"
  vpc_id      = module.vpc.vpc_id
  tags = var.managed_tags
}
# allow SSH in from anywhere in the VPC
resource "aws_security_group_rule" "services_wg_mgmt_one-ssh" {
    type = "ingress"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [module.vpc.vpc_cidr_block]
    security_group_id = aws_security_group.services_wg_mgmt_one.id
}
# egress is open
resource "aws_security_group_rule" "services_wg_mgmt_one-egress" {
    type = "egress"
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.services_wg_mgmt_one.id
}
# End rules - services worker group one

# Begin rules - gameservers worker group UDP access (public)
resource "aws_security_group" "gameservers_wg_udp" {
  name_prefix = "gameservers_wg_udp"
  description = "allow UDP ingress to gameservers"
  vpc_id      = module.vpc.vpc_id
  tags = var.managed_tags
}
# Open UDP on the gameservers 
resource "aws_security_group_rule" "gameservers_wg_udp-7k-8k" {
    type = "ingress"
    protocol = "udp"
    from_port = 7000
    to_port = 8000
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.gameservers_wg_udp.id
}
resource "aws_security_group_rule" "gameservers_wg_tcp-8080" {
    type = "ingress"
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = [module.vpc.vpc_cidr_block]
    security_group_id = aws_security_group.gameservers_wg_udp.id
}
# End rules - gameservers worker group UDP access (public)
# Begin rules - gameservers worker group management
resource "aws_security_group" "gameservers_wg_mgmt" {
  name_prefix = "gameservers_wg_mgmt"
  description = "allow access to manage gameservers"
  vpc_id      = module.vpc.vpc_id
  tags = var.managed_tags
}
# allow connections to gRPC/HTTP Agones SDK interface from anywhere in the cluster
resource "aws_security_group_rule" "gameservers_wg_agones_sdk" {
    type = "ingress"
    protocol = "tcp"
    from_port = 9357
    to_port = 9358
    cidr_blocks = [module.vpc.vpc_cidr_block]
    security_group_id = aws_security_group.gameservers_wg_mgmt.id
}
# End rules - gameservers worker group managment access
