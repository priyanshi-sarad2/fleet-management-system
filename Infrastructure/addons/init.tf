# Providers for the EKS ADD-ONS layer.
#
# This layer runs AFTER the infra layer (separate state). It connects to the
# already-created EKS cluster and installs platform add-ons (External Secrets
# Operator, etc.) using the helm/kubernetes providers.
#
# Here we connect via the local kubeconfig file you generate with:
#   AWS_PROFILE=fleetman-prod aws eks update-kubeconfig \
#     --region us-east-1 --name fleetman-eks-cluster --kubeconfig ~/.kube/fleetman-prod
#
# `config_context` must EXACTLY match a context name inside that kubeconfig.
# (Omit it to fall back to the file's current-context.)

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

provider "kubernetes" {
  config_path    = "~/.kube/fleetman-prod"
  config_context = "arn:aws:eks:us-east-1:176777036446:cluster/fleetman-eks-cluster"
}

# helm provider v3 uses attribute syntax for the kubernetes config (`kubernetes = {}`).
provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/fleetman-prod"
    config_context = "arn:aws:eks:us-east-1:176777036446:cluster/fleetman-eks-cluster"
  }
}
