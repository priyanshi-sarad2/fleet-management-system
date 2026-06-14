# Providers for the EKS ADD-ONS layer.
#
# The cluster is created in the INFRA layer (separate state), so this layer does NOT
# have a `module.eks`. It looks the cluster up with a data source and connects via the
# local kubeconfig you generated with `aws eks update-kubeconfig`.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.49.0"
    }
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

provider "aws" {
  region = var.region
}

locals {
  cluster_name = "${var.project_name}-eks-cluster"
}

# Look up the existing cluster from the infra layer (must already exist).
data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

provider "kubernetes" {
  config_path = "~/.kube/fleetman-prod"
  # `aws eks update-kubeconfig` names the context with the cluster ARN.
  config_context = data.aws_eks_cluster.this.arn
}

# helm provider v3 uses attribute syntax for the kubernetes config.
provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/fleetman-prod"
    config_context = data.aws_eks_cluster.this.arn
  }
}
