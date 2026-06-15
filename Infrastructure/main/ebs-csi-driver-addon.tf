##########    Amazon EBS CSI Driver Add-on    ##########
/*
Amazon EBS CSI Driver is an EKS add-on that allows Kubernetes workloads to
use Amazon EBS volumes for persistent storage. It is not a Kubernetes
StorageClass itself; rather, it is the driver/add-on that a StorageClass uses.

We manage the EBS CSI Driver add-on separately from the EKS module add-ons
to avoid a Terraform dependency cycle.

What we want Terraform to handle:
- create the EKS cluster
- create the IRSA IAM role for the EBS CSI Driver
- create the EBS CSI Driver add-on
- wire the add-on service account to the IAM role using
  `service_account_role_arn`

Why the dependency cycle happens if this add-on is kept inside `module.eks`
addons:
- the add-on would need `service_account_role_arn`
- that IAM role ARN comes from the IRSA role
- the IRSA role needs the cluster OIDC provider information
- that OIDC provider information is only available after the EKS cluster is
  created by `module.eks`

So the dependency becomes:
- `module.eks` add-on needs the IRSA role
- IRSA role needs the cluster OIDC information from `module.eks`

That creates a Terraform dependency cycle.

Fix:
- create the EKS cluster first via `module.eks`
- use the EKS module's OIDC provider output
- create the EBS CSI Driver IRSA role
- create the EBS CSI Driver add-on separately
- pass `service_account_role_arn` to the add-on so EKS manages the service
  account to IAM role association automatically

This avoids the dependency loop and keeps the full setup managed in Terraform.
*/


##########    IRSA IAM Role for Amazon EBS CSI Driver    ##########

module "irsa-ebs-csi-driver-iam-role" {
  source = "../modules/iam-module/iam-role-for-service-account"

  create      = var.create_eks_ebs_csi_driver_addon
  region      = var.region
  name        = "${var.project_name}-ebs-csi-driver-role"
  description = "IRSA role for Amazon EBS CSI driver (EKS add-on)"

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  # When EBS CSI Driver is installed as EKS addon - it will get installed in "kube-system" namespace - and will create a service account called "ebs-csi-controller-sa"
  /*
    This part will also set the trust policy for the IAM role.
    It will set the trust policy for the IAM role to allow the service accounts to assume the role.

    For IRSA, the trust policy says:
    - trust this OIDC provider
    - and only allow this Kubernetes namespace + ServiceAccount to assume the role

    This is what tells AWS:
    - trust tokens from this cluster’s OIDC provider
    - only allow kube-system/ebs-csi-controller-sa to assume the role
  */

  # Attach the EBS CSI permissions policy (so the controller can create/attach volumes)
  attach_ebs_csi_policy = true
  ebs_csi_kms_cmk_arns  = []
}


/*  attach_ebs_csi_policy = true - means we are 
attaching the standard EBS CSI permissions policy for 
this IRSA role, so we do not need to create a separate 
custom policy ourselves.

These permissions are used by the EBS CSI controller 
to call AWS APIs for storage operations such as 
creating, attaching, detaching, deleting, and 
describing EBS volumes and snapshots for Kubernetes 
PVCs/PVs.

ebs_csi_kms_cmk_arns = [] - means we are not using a 
  customer-managed KMS key, so we can leave this empty.
*/






##########    Amazon EBS CSI Driver Add-on    ##########

module "eks-addons-ebs-csi-driver" {
  source = "../modules/eks-addons"

  create        = var.create_eks_ebs_csi_driver_addon
  region        = var.region
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.eks_ebs_csi_driver_addon_version
  cluster_name  = "${var.project_name}-eks-cluster"

  /* 
  Let the EKS add-on manage the service account -> IAM role association.
  This is done automatically by terraform using "service_account_role_arn"

  This means annotate the EBS CSI driver service account to use the IAM role.
  */
  service_account_role_arn    = module.irsa-ebs-csi-driver-iam-role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  depends_on = [
    module.eks,
    module.irsa-ebs-csi-driver-iam-role,
  ]
}
