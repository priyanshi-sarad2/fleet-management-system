###   Helm   ###

# One Helm release per entry in var.helm_charts (keyed by release name).
# Empty map -> nothing is installed.

locals {
  # VPC ID pulled dynamically from the existing EKS cluster data source (no hardcoding).
  # Any chart that sets `inject_vpc_id = true` gets this appended to its set values.
  # (Needed by the AWS Load Balancer Controller, whose pods can't reach EC2 IMDS to
  # auto-discover the VPC. Other charts opt in only if they need it.)
  vpc_id_set = [
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

  # `set` is a list of {name, value} objects from tfvars. Charts that request it
  # (inject_vpc_id = true) also get the dynamically-discovered VPC ID appended.
  helm_set = each.value.inject_vpc_id ? concat(each.value.set, local.vpc_id_set) : each.value.set
}
