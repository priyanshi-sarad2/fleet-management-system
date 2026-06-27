####  EKS  ####

# ---------------------------------------------------------------------------
# EKS Access Entries that must reference resources created in THIS layer.
# Their ARNs are only known after apply, so they can't be expressed in the
# static prod-terraform.tfvars. Define them here and merge with the
# tfvars-driven entries inside the module call below.
# ---------------------------------------------------------------------------
locals {
  # Account root admin access entry. This references var.account_id, and a .tfvars
  # file may only contain literal values (no variable references), so the entry is
  # built here instead of in prod-terraform.tfvars.
  # Why: the IAM user who created the cluster has admin on the cluster, but the AWS
  # account root does NOT automatically get EKS cluster access - so we grant it via
  # this access entry + cluster-admin policy association.
  eks_access_entry_account_root_admin = {
    account_root_admin = {
      principal_arn = "arn:aws:iam::${var.account_id}:root"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_access_entries = merge(
    # CodePipeline/CodeBuild role: the EKS deploy stage (helm upgrade) runs as
    # this role. The app charts include an ExternalSecret (external-secrets.io CRD).
    # AWS's namespace-scoped AmazonEKSAdminPolicy maps to the built-in `admin`
    # role, which does NOT cover arbitrary CRDs, so Helm can't manage the
    # ExternalSecret. Cluster-admin is the simplest policy that covers CRDs.
    # (For stricter least-privilege, map the role to a kubernetes group via an
    # access entry and bind a custom Role granting external-secrets.io in the
    # app namespace instead.)
    var.create_codepipeline ? {
      codepipeline = {
        principal_arn = module.iam-assumable-role-codepipeline.iam_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
  )
}

module "eks" {
  source             = "../modules/eks"
  create_eks_cluster = var.create_eks_cluster
  eks_region         = var.region
  eks_cluster_name   = "${var.project_name}-eks-cluster"

  # Cluster-only tags are set here (not in tfvars)
  eks_cluster_tags = {
    Project     = var.project_name
    Environment = var.env
    Terraform   = "true"
  }

  # Global tags applied to all resources created by the EKS module
  eks_tags = {
    Project     = var.project_name
    Environment = var.env
    Terraform   = "true"
  }




  ###############    Cluster settings    ###############
  kubernetes_version      = var.kubernetes_version
  eks_deletion_protection = var.eks_deletion_protection
  # Control plane upgrade support policy
  eks_control_plane_upgrade_policy = {
    support_type = "STANDARD"
  }


  ###############    Cluster Authentication    ###############
  eks_authentication_mode = var.eks_authentication_mode

  eks_access_entries = merge(
    # Account root admin (built in locals because it references var.account_id)
    local.eks_access_entry_account_root_admin,

    # Entries that reference resources created in this layer (e.g. CodePipeline role)
    local.eks_managed_access_entries,

    # Optional extra static entries from tfvars (principals known ahead of time)
    var.eks_access_entries
  )
  /*
  Important: By setting the "enable_cluster_creator_admin_permissions" to "true" - I gave "devops" user admin access to this EKS cluster via EKS Access Entry.

  But the root user of my AWS account - does not have admin access to this EKS cluster - even though it has admin access to AWS account.

  So, I need to give root user admin access to this EKS cluster via EKS Access Entry. I need to create an EKS Access Entry for it.

  ADDING additional users - If we want to give access to any other IAM user/role to access this EKS cluster - we can add them here.

  */

  eks_endpoint_private_access      = var.eks_endpoint_private_access
  eks_endpoint_public_access       = var.eks_endpoint_public_access
  eks_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs



  ###############    CloudWatch Log Group    ###############
  eks_cluster_cloudwatch_log_group = var.create_eks_cluster_cloudwatch_log_group
  eks_cluster_enabled_log_types    = var.eks_cluster_enabled_log_types



  ###############    Network    ###############
  eks_vpc_id = module.vpc.vpc_id
  # ip_family: chooses whether pods/services use IPv4 (common) or IPv6 addresses (must be decided at cluster creation)
  eks_ip_family = "ipv4"
  # service_ipv4_cidr: the IPv4 range used for Kubernetes Service (ClusterIP) IPs CIDR; leave null to let EKS pick the default
  eks_service_ipv4_cidr = null

  # Both control-plane and node-group should be launched in private subnet
  eks_control_plane_subnet_ids = module.vpc.private_subnet_ids
  # This is where EKS cluster control plane (ENIs) will be provisioned
  eks_node_group_subnet_ids = module.vpc.private_subnet_ids
  # This is where EKS node group (EC2 instances and its ENIs) will be provisioned



  ###############    Security Group    ###############
  control_plane_sg_name                 = "${var.project_name}-eks-control-plane"
  eks_control_plane_sg_additional_rules = var.eks_control_plane_sg_additional_rules
  # egress rules for cluster/control-plane default SG
  eks_node_group_sg_name             = "${var.project_name}-eks-node-group"
  eks_node_group_sg_additional_rules = var.eks_node_group_sg_additional_rules # If I want to add additional rules to node group SG - I can add them here


  ###############    IRSA    ###############
  enable_irsa                     = var.enable_irsa
  openid_connect_audiences        = var.openid_connect_audiences
  include_oidc_root_ca_thumbprint = var.include_oidc_root_ca_thumbprint
  custom_oidc_thumbprints         = var.custom_oidc_thumbprints



  ###############    IAM Role    ###############
  # IAM Role for EKS cluster (control plane)
  eks_control_plane_iam_role_name = "${var.project_name}-eks-control-plane"



  ###############    EKS Managed Node Groups    ###############
  eks_managed_node_groups = {
    fleetman-node-group = {
      create         = var.create_eks_cluster
      name           = "${var.project_name}-eks-node-group"
      instance_types = var.node_group_instance_types
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      disk_size      = var.node_group_ebs_disk_size
      force_delete   = true

      tags = {
        Name = "worker" # name of ec2 instance of managed node group
      }

      # Let the module generate bootstrap user data so nodes join the EKS cluster
      enable_bootstrap_user_data = true

      # Node Group ASG - Launch Template
      create_launch_template          = true
      launch_template_name            = "${var.project_name}-eks-managed-node-group"
      launch_template_use_name_prefix = false
      ebs_optimized                   = true
      disable_api_termination         = false # ec2 termination protection


      # IAM Role - for managed node group - their instance profile
      create_iam_role          = true
      iam_role_name            = "${var.project_name}-eks-managed-node-group"
      iam_role_use_name_prefix = false
      # Critical for aws-node (VPC CNI) to attach secondary ENIs / assign pod IPs.
      # AWS official guidance calls this out as a common root cause of CNI/network plugin failures.
      iam_role_attach_cni_policy   = true
      iam_role_additional_policies = var.node_group_iam_role_additional_policies


      # Security Group
      create_security_group          = true
      security_group_name            = "${var.project_name}-eks-managed-node-group"
      security_group_use_name_prefix = false


      # EKS creates a SG for node-group - so we don't generally have to attach the cluster's primary SG to node-group
      attach_cluster_primary_security_group = false
    }
  }



  ###############    EKS Add-ons    ###############
  eks_addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      # before_compute = true (inside your vpc-cni add-on config) tells the official terraform-aws-eks module to install/activate that EKS managed add-on before it creates any compute, i.e. before your managed node group instances are provisioned.
      # For vpc-cni, this is important because the nodes need the CNI components (aws-node DaemonSet) to come up so the node can become Ready and pods can get networking/IPs.
      before_compute = true
      # Avoid rollbacks when IaC meets an existing/default add-on configuration.
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      # Don't accidentally remove pod networking from a live cluster.
      preserve = true
    }
  }


}