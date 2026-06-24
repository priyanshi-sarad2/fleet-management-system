variable "create_eks_cluster" {
  description = "Whether to create the EKS cluster (and related resources in the upstream module)"
  type        = bool
  default     = false
}

variable "eks_region" {
  description = "AWS region for EKS resources (defaults to provider region if null)"
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster (e.g. 1.33)"
  type        = string
  default     = null
}

variable "eks_deletion_protection" {
  description = "Whether to enable EKS deletion protection"
  type        = bool
  default     = null
}

variable "eks_control_plane_sg_additional_rules" {
  description = "Additional security group rules to add to the module-created EKS cluster security group (control plane SG)"
  type        = any
  default     = {}
}

variable "eks_control_plane_upgrade_policy" {
  description = "EKS cluster upgrade policy (control plane). support_type = STANDARD or EXTENDED"
  type = object({
    support_type = optional(string, "STANDARD")
  })
  default = {
    support_type = "STANDARD"
  }
}

variable "eks_vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
  default     = null
}

variable "eks_subnet_ids" {
  description = "Subnet IDs for EKS nodes/control plane ENIs"
  type        = list(string)
  default     = []
}

variable "eks_control_plane_subnet_ids" {
  description = "Subnet IDs where the EKS control plane ENIs will be placed"
  type        = list(string)
  default     = []
}

variable "eks_node_group_subnet_ids" {
  description = "Subnet IDs where the EKS nodes/node groups will be placed"
  type        = list(string)
  default     = []
}

variable "eks_endpoint_private_access" {
  description = "Whether the EKS API endpoint is reachable from inside the VPC"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS API endpoint is reachable from the public internet"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint (only used when eks_endpoint_public_access=true)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_ip_family" {
  description = "IP family for Kubernetes pod/service networking: ipv4 or ipv6"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "ipv6"], var.eks_ip_family)
    error_message = "eks_ip_family must be either \"ipv4\" or \"ipv6\"."
  }
}

variable "eks_service_ipv4_cidr" {
  description = "Optional Kubernetes Service (ClusterIP) IPv4 CIDR. Leave null to use EKS/Kubernetes default."
  type        = string
  default     = null
}

variable "eks_authentication_mode" {
  description = "EKS authentication mode: CONFIG_MAP, API, or API_AND_CONFIG_MAP"
  type        = string
  default     = "API"

  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.eks_authentication_mode)
    error_message = "eks_authentication_mode must be one of: CONFIG_MAP, API, API_AND_CONFIG_MAP."
  }
}

variable "eks_cluster_tags" {
  description = "Extra tags to apply to the EKS cluster resource (cluster-only)"
  type        = map(string)
  default     = {}
}

variable "eks_access_entries" {
  description = "EKS Access Entries (AWS-side cluster access) used when authentication_mode is API or API_AND_CONFIG_MAP"
  type        = any
  default     = {}
}

variable "eks_cluster_existing_security_group_id" {
  description = "Optional existing security group ID to attach to the EKS cluster (in addition to the cluster primary SG that EKS creates)"
  type        = string
  default     = null
}

variable "eks_node_existing_security_group_id" {
  description = "Optional existing security group ID to attach to EKS nodes/node groups"
  type        = string
  default     = null
}

variable "eks_cluster_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch Log Group for EKS cluster logs (only relevant when create_eks_cluster=true)"
  type        = bool
  default     = true
}

variable "eks_cluster_enabled_log_types" {
  description = "EKS control-plane log types to ship to CloudWatch (e.g. [\"audit\",\"api\",\"authenticator\"]). Empty list disables control-plane logging."
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
}

variable "control_plane_sg_name" {
  description = "Optional name for the EKS cluster security group created by the module"
  type        = string
  default     = null
}

variable "eks_control_plane_iam_role_name" {
  description = "Optional name for the EKS cluster IAM role created by the module"
  type        = string
  default     = null
}

variable "eks_node_group_sg_name" {
  description = "Optional name for the EKS shared node security group created by the module"
  type        = string
  default     = null
}

variable "eks_node_group_sg_additional_rules" {
  description = "Additional security group rules to add to the EKS node security group created by the module"
  type = map(object({
    protocol                      = optional(string, "tcp")
    from_port                     = number
    to_port                       = number
    type                          = optional(string, "ingress")
    description                   = optional(string)
    cidr_blocks                   = optional(list(string))
    ipv6_cidr_blocks              = optional(list(string))
    prefix_list_ids               = optional(list(string))
    self                          = optional(bool)
    source_cluster_security_group = optional(bool, false)
    source_security_group_id      = optional(string)
  }))
  default = {}
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions (passed to terraform-aws-modules/eks/aws)"
  type        = any
  default     = null
}

variable "eks_tags" {
  description = "Tags applied to all resources created by the EKS module"
  type        = map(string)
  default     = {}
}

variable "eks_addons" {
  description = "EKS managed add-ons configuration passed to terraform-aws-modules/eks/aws `addons` input"
  type = map(object({
    name                 = optional(string) # falls back to map key
    before_compute       = optional(bool, false)
    most_recent          = optional(bool, true)
    addon_version        = optional(string)
    configuration_values = optional(string)

    pod_identity_association = optional(list(object({
      role_arn        = string
      service_account = string
    })))

    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})

    tags = optional(map(string), {})
  }))

  # Default to null so the root module (`main/eks.tf`) explicitly decides which
  # add-ons are enabled and how they are configured.
  default = null
}

################################################################################
# IRSA (IAM Roles for Service Accounts)
################################################################################

variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "openid_connect_audiences" {
  description = "List of OpenID Connect audience client IDs to add to the IRSA provider (sts.amazonaws.com is always included)"
  type        = list(string)
  default     = []
}

variable "include_oidc_root_ca_thumbprint" {
  description = "Determines whether to include the root CA thumbprint in the OIDC identity provider's server certificate(s)"
  type        = bool
  default     = true
}

variable "custom_oidc_thumbprints" {
  description = "Additional list of server certificate thumbprints for the OIDC identity provider's server certificate(s)"
  type        = list(string)
  default     = []
}

