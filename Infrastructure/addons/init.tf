terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.0"
      config_path    = "~/.kube/fleetman-prod"
      config_context = "fleetman-eks-cluster"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
      kubernetes = {
        config_path = "~/.kube/fleetman-prod"
      }
    }
  }
}

provider "aws" {
  region = var.region
}