# Providers for the EKS ADD-ONS layer.
#
# The cluster is created in the INFRA layer (separate state), so this layer does NOT have a `module.eks`. It looks the cluster up with a data source and connects via the local kubeconfig you generated with `aws eks update-kubeconfig`.

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
  }
}

locals {
  cluster_name = "${var.project_name}-eks-cluster"
}

# Data source is a read-only lookup. Fetching the details of an eks cluster that already exists from the infra layer.
data "aws_eks_cluster" "eks_cluster_data" {
  name = local.cluster_name
}

provider "kubernetes" {
  config_path = "~/.kube/fleetman-prod"
  config_context = data.aws_eks_cluster.eks_cluster_data.arn
}


provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/fleetman-prod"
    config_context = data.aws_eks_cluster.eks_cluster_data.arn
  }
}