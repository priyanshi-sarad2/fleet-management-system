###  IAM Role for Service Accounts  ###

module "iam_role_for_service_accounts" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.6.1"

  create          = var.create
  region          = var.region
  name            = var.name
  use_name_prefix = false
  path            = "/"
  description     = var.description

  oidc_providers = var.oidc_providers
  /*
    This part will also set the trust policy for the IAM role.
    It will set the trust policy for the IAM role to allow the service accounts to assume the role.

    For IRSA, the trust policy says:
    - trust this OIDC provider
    - and only allow this Kubernetes namespace + ServiceAccount to assume the role
  */


  attach_ebs_csi_policy = var.attach_ebs_csi_policy
  /*
    If true, the upstream IAM module creates and attaches the standard
    EBS CSI permissions policy for this IRSA role, so we do not need to
    create a separate custom policy ourselves.

    These permissions are used by the EBS CSI controller to call AWS APIs
    for storage operations such as creating, attaching, detaching, deleting,
    and describing EBS volumes and snapshots for Kubernetes PVCs/PVs.
  */
  
  ebs_csi_kms_cmk_arns  = var.ebs_csi_kms_cmk_arns
  /*
    Only needed when EBS volumes use a customer-managed KMS key; grants the
    EBS CSI role permission to use those key ARNs for encrypted volume operations.
    If you are not using a customer-managed KMS key, you can leave this empty.
  */ 

  attach_amazon_managed_service_prometheus_policy = var.attach_amazon_managed_service_prometheus_policy
  amazon_managed_service_prometheus_workspace_arns = var.amazon_managed_service_prometheus_workspace_arns
  /*
    For ADOT or Prometheus running in EKS, this attaches the upstream AMP IAM
    policy so the IRSA role can remote_write and read AMP metadata for the
    specified workspace ARNs.
  */
}

