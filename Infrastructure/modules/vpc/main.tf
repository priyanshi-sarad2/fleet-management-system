########     VPC     ########

module "vpc" {
  source      = "terraform-aws-modules/vpc/aws"
  version     = "6.6.1"
  create_vpc  = var.create_vpc
  name        = var.name
  cidr        = var.cidr
  azs         = var.availability_zones
  create_igw  = true

  # Public subnet and Public subnet Network ACL
  public_subnets               = var.public_subnets
  public_subnet_names          = var.public_subnet_names
  public_dedicated_network_acl = var.enable_public_dedicated_network_acl
  public_inbound_acl_rules     = var.public_inbound_acl_rules
  public_outbound_acl_rules    = var.public_outbound_acl_rules

  # Private subnet and Private subnet Network ACL
  private_subnets               = var.private_subnets
  private_subnet_names          = var.private_subnet_names
  private_dedicated_network_acl = var.enable_private_dedicated_network_acl
  private_inbound_acl_rules     = var.private_inbound_acl_rules
  private_outbound_acl_rules    = var.private_outbound_acl_rules

  /*
  A Network ACL (Access Control List) is a stateless security feature in AWS 
  that controls inbound and outbound traffic at the subnet level within a VPC. 
  It functions as a firewall, allowing or denying traffic based on rules you define, such as IP address, port, and protocol. 
  Network ACLs are applied to individual subnets, and each subnet can have its own set of rules. 
  It helps manage traffic between resources in different subnets and control internet access to specific parts of your network, ensuring the security and proper isolation of your resources.

  By default, Network ACLs allow all inbound and outbound traffic. You can create custom rules to both allow and deny specific traffic based on IP, port, and protocol.
*/


  # Database subnet and Database subnet Network ACL
  database_subnets                   = var.database_subnets
  database_subnet_names              = var.database_subnet_names
  database_dedicated_network_acl     = var.enable_database_dedicated_network_acl
  database_inbound_acl_rules         = var.database_inbound_acl_rules
  database_outbound_acl_rules        = var.database_outbound_acl_rules
  create_database_subnet_route_table = true 
  /* If true, seperate route table will be created for db subnets as well. If this is not true, by default it won't create any route table and uses same route table as private subnet which is wrong in our case because in our case I am giving private subnet outbound internet access using NAT Gateway, which will alter private subnet route tables.
  So, I want seperate route tables for db-subnet, so that their traffic can be handled differently and there is no outbound internet access given to db - unlesss ofcourse I want it
  */
  create_database_nat_gateway_route      = false
  create_database_internet_gateway_route = false
  create_database_subnet_group           = var.create_database_subnet_group
  database_subnet_group_name             = var.database_subnet_group_name


  enable_nat_gateway               = true
  single_nat_gateway               = true
  one_nat_gateway_per_az           = false
  create_private_nat_gateway_route = true


  tags = {
    Terraform = "True"
    Project   = var.name
    Service   = var.app
  }
}