# Amazon MQ

module "amazon-mq" {
  source = "../modules/amazon-mq"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnet_ids[0]] # SINGLE_INSTANCE needs exactly one subnet

  engine_type           = var.mq_engine_type
  engine_version        = var.mq_engine_version
  host_instance_type    = var.mq_host_instance_type
  allowed_ingress_ports = var.mq_allowed_ingress_ports

  project_name = var.project_name
}
