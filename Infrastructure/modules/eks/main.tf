###  EKS Setup  ###

module "eks" {
  source      = "terraform-aws-modules/eks/aws"
  version     = "21.23.0"
  create      = var.create_eks_cluster
  region      = var.eks_region
  name        = var.eks_cluster_name

  # EKS Auto Mode (compute_config) disabled for now
  compute_config = {
    enabled = false
  }

  # Extra tags only for the EKS cluster resource (not all resources)
  cluster_tags = var.eks_cluster_tags

  # Global tags applied to all resources created by the EKS module
  tags = var.eks_tags


  ###############    Cluster settings    ###############
  kubernetes_version   = var.kubernetes_version
  deletion_protection  = var.eks_deletion_protection
  force_update_version = false

  # upgrade_policy controls STANDARD vs EXTENDED support; null = use EKS default (STANDARD)
  upgrade_policy = var.eks_control_plane_upgrade_policy




  ###############    Cluster Authentication    ###############
  authentication_mode = var.eks_authentication_mode
  /*
  authentication_mode = how EKS decides who can access the cluster.
  Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`

  - CONFIG_MAP: old way. You edit the in-cluster `aws-auth` ConfigMap to add IAM users/roles and their Kubernetes groups.

  - API: new way (recommended) You create EKS "Access Entries" in AWS for an IAM user/role and attach admin/view policies. You do NOT edit `aws-auth`. Instead you tell AWS:
    1) "This IAM user/role can access this cluster" (Access Entry)
    2) "This is their permission level" (attach an EKS access policy like Admin/View)

  - API_AND_CONFIG_MAP: hybrid. Both Access Entries + `aws-auth` ConfigMap are used (good for migration) - IF let say you are migrating from on-prem to AWS EKS.
  */


  enable_cluster_creator_admin_permissions = true
  /*
    Gives the IAM identity running Terraform (you) admin access to cluster via an EKS Access Entry
    Now, the aws profile I created woith credentials - is for my "devops" IAM user - who is also the creator of cluster
    So, I can give admin access to this user to access the cluster via EKS Access Entry

    Now, even though this "devops" has IAM policy attached to it - which gives it admin access for AWS accounts - it does not mean that it will automatically have admin access to EKS cluster.
    We need to give it admin access to EKS cluster via EKS Access Entry.

    So setting this flag to true will give admin access to the "devops" user for this EKS cluster and will create an EKS Access Entry for it.
  */

  access_entries = var.eks_access_entries
  /*
   Access Entries = AWS-side list of who can access this cluster and what permissions they get (used in API modes)

   Eg: if you want to give read access of cluster to developers

   Important: By setting the "enable_cluster_creator_admin_permissions" to "true" - I gave "devops" user admin access to this EKS cluster via EKS Access Entry.

   But the root user of my AWS account - does not have admin access to this EKS cluster - even though it has admin access to AWS account.

   So, I need to give root user admin access to this EKS cluster via EKS Access Entry. I need to create an EKS Access Entry for it.
   */

  
  endpoint_private_access = var.eks_endpoint_private_access
  /*
  Private API endpoint ON (access EKS API from inside VPC, e.g., via bastion/VPN/SSM)
  worker nodes use private API endpoint to join the cluster
  for production, it is good to keep this private
  If only private endpoint is enabled - then we need to use bastion host to access the cluster
  */
  
  endpoint_public_access = var.eks_endpoint_public_access
  /*
  To access cluster from outside VPC - I will need to enable public API endpoint
  to access it from my local machine
  */

  # If endpoint_public_access=true, restrict who can reach the public EKS API (e.g., office public IP). Ignored when endpoint_public_access=false.
  endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  /*
    For production, it is good to not allow direct public API access to cluster. Instead create a bastion host, install kubectl in it - and access it from there.

    For my testing - I will access it publicly from my local machine.
  */





  ###############    CloudWatch Log Group    ###############
  create_cloudwatch_log_group = var.eks_cluster_cloudwatch_log_group

  # Control-plane log types EKS ships to CloudWatch (/aws/eks/<cluster>/cluster).
  # Upstream default is ["audit","api","authenticator"]; set to [] to disable
  # control-plane logging (we collect app pod logs via Fluent Bit instead).
  enabled_log_types = var.eks_cluster_enabled_log_types



  ###############    Network    ###############
  vpc_id             = var.eks_vpc_id

  # ip_family: chooses whether pods/services use IPv4 (common) or IPv6 addresses (must be decided at cluster creation)
  ip_family = var.eks_ip_family

  # service_ipv4_cidr: the IPv4 range used for Kubernetes Service (ClusterIP) IPs CIDR; leave null to let EKS pick the default
  service_ipv4_cidr = var.eks_service_ipv4_cidr

  # This is where EKS cluster control plane (ENIs) will be provisioned
  control_plane_subnet_ids = var.eks_control_plane_subnet_ids

  # This is where EKS node group (EC2 instances and its ENIs) will be provisioned
  subnet_ids               = var.eks_node_group_subnet_ids




  ###############    Security Group    ###############
  # Cluster OR Control Plane Security Group
  # SG: EKS creates a primary SG by default for control-plane / cluster
  # doing below to give it a name
  # we can add additional rules to it
  # eks obviously add some rules on its own
  create_security_group          = true
  security_group_name            = var.control_plane_sg_name
  security_group_use_name_prefix = false

  # IMPORTANT: ensure the control-plane SG has egress so the control plane can reach kubelets on nodes.
  # For some reason when cluster/control-plane default SG is created, it does not have egress rule.
  # Without this, node groups can fail with NodeCreationFailure/Unhealthy nodes.
  # This rule is not added by default
  security_group_additional_rules = var.eks_control_plane_sg_additional_rules

  create_node_security_group          = true
  node_security_group_name            = var.eks_node_group_sg_name
  node_security_group_use_name_prefix = false
  node_security_group_additional_rules = var.eks_node_group_sg_additional_rules




  ###############    IRSA    ###############

  # IRSA (OIDC provider for service account -> IAM role)
  enable_irsa                     = var.enable_irsa
  openid_connect_audiences         = var.openid_connect_audiences
  include_oidc_root_ca_thumbprint  = var.include_oidc_root_ca_thumbprint
  custom_oidc_thumbprints          = var.custom_oidc_thumbprints




  ###############    IAM Role    ###############
  # IAM role of cluster / control-plane settings pending
  create_iam_role          = true # true by default
  iam_role_name            = var.eks_control_plane_iam_role_name
  iam_role_use_name_prefix = false

 


  ###############    EKS Managed Node Groups    ###############
  eks_managed_node_groups = var.eks_managed_node_groups



  ###############    EKS Add-ons    ###############
  addons = var.eks_addons
}