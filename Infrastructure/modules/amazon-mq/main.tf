########    AMAZON MQ     ########

module "mq-broker" {
  source        = "cloudposse/mq-broker/aws"
  version       = "3.6.0"

  namespace = var.project_name # e.g. "fleetman"
  name      = "mq"             # broker name becomes "<namespace>-mq", e.g. "fleetman-mq"

  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids

  allowed_ingress_ports = var.allowed_ingress_ports

  engine_type = var.engine_type
  engine_version = var.engine_version
  host_instance_type = var.host_instance_type

  publicly_accessible = false
  apply_immediately   = true
  auto_minor_version_upgrade = true
  deployment_mode = "SINGLE_INSTANCE"

  tags = {
    Terraform = "True"
    Project   = var.project_name
    Service   = "amazon-mq"
  }

}
