########    AMAZON MQ     ########

module "amazon-mq" {
  source = "../modules/amazon-mq"
  count  = var.create_amazon_mq ? 1 : 0

  project_name  = var.project_name

  vpc_id        = module.vpc.vpc_id
  subnet_ids    = [module.vpc.private_subnet_ids[0]] 
  # SINGLE_INSTANCE needs exactly one subnet

  engine_type           = var.mq_engine_type
  engine_version        = var.mq_engine_version
  host_instance_type    = var.mq_host_instance_type
  allowed_ingress_ports = var.mq_allowed_ingress_ports
  # The broker and the app pods/nodes live in the private subnets, so scope ingress to
  # just those CIDRs (tighter than the whole VPC CIDR).
  allowed_cidr_blocks   = module.vpc.private_subnet_cidrs

  mq_admin_user       = var.mq_admin_user
  mq_application_user  = var.mq_application_user
}
