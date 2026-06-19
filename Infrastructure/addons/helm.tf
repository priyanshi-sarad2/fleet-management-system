###   Helm   ###

# One Helm release per entry in var.helm_charts (keyed by release name).
# Empty map -> nothing is installed.

locals {
  # The AWS Load Balancer Controller needs the VPC ID, but its pods can't reach EC2 IMDS
  # to auto-discover it (node IMDS hop limit). Instead of hardcoding the VPC ID in tfvars,
  # we pull it dynamically from the existing EKS cluster data source and append it to that
  # chart's set values only.
  alb_controller_release = "load-balancer-controller"

  alb_controller_vpc_set = [
    {
      name  = "vpcId"
      value = data.aws_eks_cluster.eks_cluster_data.vpc_config[0].vpc_id
    }
  ]
}

module "helm_charts" {
  source   = "../modules/helm"
  for_each = var.helm_charts

  helm_release_name  = each.key
  helm_repository    = each.value.repository
  helm_chart_name    = each.value.chart_name
  helm_chart_version = each.value.chart_version
  helm_namespace     = each.value.namespace

  # `set` is a list of {name, value} objects from tfvars. For the ALB controller we
  # concat the dynamically-discovered VPC ID onto it; all other charts use tfvars as-is.
  helm_set = (
    each.key == local.alb_controller_release
    ? concat(each.value.set, local.alb_controller_vpc_set)
    : each.value.set
  )
}
