########    ECR     ########

module "ecr" {
  source   = "../modules/ecr"
  for_each = { for app in var.apps : "ecr-${app}" => app }

  create_ecr_repository = var.create_ecr_repository
  name                  = var.project_name
  ecr_repository_name   = "${var.project_name}-${each.value}"
  ecr_retention_count   = var.ecr_retention_count
}





# module "ecr-aws-prometheus-adot-writer" {
#   source                = "../modules/ecr"
#   create_ecr_repository = var.create_aws_prometheus_adot_writer_ecr
#   name                  = var.project_name
#   ecr_repository_name   = "${var.project_name}-aws-prometheus-adot-writer"
#   ecr_retention_count   = 3
# }