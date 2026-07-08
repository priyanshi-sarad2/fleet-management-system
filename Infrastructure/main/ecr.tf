########    ECR     ########

module "ecr" {
  source   = "../modules/ecr"
  for_each = { for app in var.apps : "ecr-${app}" => app }

  create_ecr_repository = var.create_ecr_repository
  name                  = var.project_name
  ecr_repository_name   = "${var.project_name}-${each.value}"
  ecr_retention_count   = var.ecr_retention_count
}




