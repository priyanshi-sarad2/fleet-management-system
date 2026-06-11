######## Global ########

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "project"
}

# Supplied via the TF_VAR_account_id environment variable (kept out of version control).
variable "account_id" {
  description = "AWS account ID. Provide via the TF_VAR_account_id environment variable."
  type        = string
}

######## VPC ########

variable "create_vpc" {
  description = "Controls if VPC should be created"
  type        = bool
  default     = false
}

variable "cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnet_names" {
  description = "Explicit values to use in the Name tag on public subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnet_names" {
  description = "Explicit values to use in the Name tag on private subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "database_subnet_names" {
  description = "Explicit values to use in the Name tag on database subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Provision a single shared NAT Gateway across all private subnets"
  type        = bool
  default     = false
}

variable "create_cloudfront_fleetman_webapp" {
  description = "Controls if the Fleetman webapp CloudFront distribution should be created"
  type        = bool
  default     = false
}

variable "fleetman_webapp_domain" {
  description = "Custom domain name for the Fleetman webapp CloudFront distribution"
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront"
  type        = string
  default     = null
}

variable "fleetman_webapp_alb_origin_domain" {
  description = "ALB DNS name used as the CloudFront origin for the Fleetman webapp"
  type        = string
  default     = null
}

######## EKS ########

variable "create_eks_cluster" {
  description = "Controls if EKS (managed Kubernetes) cluster should be created"
  type        = bool
  default     = false
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

variable "create_eks_cluster_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch Log Group for EKS cluster logs"
  type        = bool
  default     = false
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

variable "eks_control_plane_sg_additional_rules" {
  description = "Additional security group rules to add to the EKS control plane security group"
  type        = any
  default     = {}
}

variable "eks_node_group_sg_additional_rules" {
  description = "Additional security group rules to add to the EKS node group security group"
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

variable "eks_authentication_mode" {
  description = "EKS authentication mode: CONFIG_MAP, API, or API_AND_CONFIG_MAP"
  type        = string
  default     = "API"

  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.eks_authentication_mode)
    error_message = "eks_authentication_mode must be one of: CONFIG_MAP, API, API_AND_CONFIG_MAP."
  }
}

variable "eks_access_entries" {
  description = "Extra EKS Access Entries (AWS-side cluster access) used when authentication_mode is API or API_AND_CONFIG_MAP"
  type        = any
  default     = {}
}

variable "eks_access_entry_account_root_admin" {
  description = "Static EKS access entry object for account root admin (kept in tfvars)"
  type        = any
  default     = null
}

######## IRSA ########

variable "enable_irsa" {
  description = "Enable IRSA by creating an IAM OIDC provider for the EKS cluster"
  type        = bool
  default     = true
}

variable "create_irsa_ebs_csi_driver_iam_role" {
  description = "Controls if the IRSA IAM role for the Amazon EBS CSI driver should be created"
  type        = bool
  default     = false
}

variable "create_eks_ebs_csi_driver_addon" {
  description = "Controls if the Amazon EBS CSI Driver EKS add-on should be created"
  type        = bool
  default     = false
}

variable "eks_ebs_csi_driver_addon_version" {
  description = "Version of the Amazon EBS CSI Driver EKS add-on"
  type        = string
  default     = null
}

variable "openid_connect_audiences" {
  description = "Extra OIDC audiences to include on the IAM OIDC provider (sts.amazonaws.com is always included)"
  type        = list(string)
  default     = []
}

variable "include_oidc_root_ca_thumbprint" {
  description = "Include the OIDC root CA thumbprint"
  type        = bool
  default     = true
}

variable "custom_oidc_thumbprints" {
  description = "Additional OIDC server certificate thumbprints (rarely needed)"
  type        = list(string)
  default     = []
}

######## ECR ########

variable "create_aws_prometheus_adot_writer_ecr" {
  description = "Controls whether the ECR repository for the AWS Prometheus ADOT writer image should be created"
  type        = bool
  default     = false
}

######## EKS Managed Node Group ########

variable "create_eks_managed_node_group" {
  description = "Controls if the EKS managed node group should be created"
  type        = bool
  default     = true
}

variable "node_group_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = null
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
  default     = null
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
  default     = null
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
  default     = null
}

variable "node_group_ebs_disk_size" {
  description = "Root EBS volume size (GiB) for EKS managed node group nodes"
  type        = number
  default     = null
}

variable "node_group_iam_role_additional_policies" {
  description = "Additional AWS managed IAM policy ARNs to attach to the EKS managed node group IAM role"
  type        = map(string)
  default     = {}
}

variable "node_group_inputs_validation" {
  description = "Internal validation switch (do not set). Ensures required node group inputs are provided when creating EKS."
  type        = bool
  default     = true

  validation {
    condition = (
      var.create_eks_cluster == false || var.node_group_inputs_validation == false || (
        var.node_group_instance_types != null &&
        var.node_group_min_size != null &&
        var.node_group_max_size != null &&
        var.node_group_desired_size != null &&
        var.node_group_ebs_disk_size != null
      )
    )
    error_message = "When create_eks_cluster=true, you must set node_group_instance_types, node_group_min_size, node_group_max_size, node_group_desired_size, and node_group_ebs_disk_size (typically via prod-terraform.tfvars)."
  }
}

######## Monitoring ########

variable "setup_eks_cluster_monitoring" {
  description = "Controls whether AMP resources and the ADOT writer IRSA role should be created for EKS monitoring"
  type        = bool
  default     = false
}

variable "prometheus_workspace_alias" {
  description = "Optional friendly name for the AMP workspace. If null, a name is derived from project and environment."
  type        = string
  default     = null
}

variable "prometheus_retention_period_in_days" {
  description = "Number of days to retain Prometheus metrics in the AMP workspace"
  type        = number
  default     = null
}

variable "prometheus_cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain AMP CloudWatch log events"
  type        = number
  default     = 30
}

variable "prometheus_resource_policy_statements" {
  description = "Optional custom AMP workspace resource policy statements. Leave null to use the defaults configured in monitoring.tf."
  type = map(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string, "Allow")
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
  default = null
}

variable "create_grafana" {
  description = "Controls whether the Amazon Managed Grafana workspace should be created"
  type        = bool
  default     = false
}

variable "create_workspace" {
  description = "Controls whether the Amazon Managed Grafana workspace resource should be created"
  type        = bool
  default     = false
}

variable "grafana_version" {
  description = "Grafana version to use for the Amazon Managed Grafana workspace"
  type        = string
  default     = "10.4"
}

variable "grafana_workspace_name" {
  description = "Name of the Amazon Managed Grafana workspace"
  type        = string
  default     = null
}

variable "grafana_workspace_description" {
  description = "Description of the Amazon Managed Grafana workspace"
  type        = string
  default     = null
}

variable "grafana_account_access_type" {
  description = "The type of account access for the Grafana workspace. Valid values are CURRENT_ACCOUNT and ORGANIZATION"
  type        = string
  default     = "CURRENT_ACCOUNT"
}

variable "grafana_permission_type" {
  description = "Permission model for the Grafana workspace. Valid values are SERVICE_MANAGED and CUSTOMER_MANAGED"
  type        = string
  default     = "SERVICE_MANAGED"
}

variable "grafana_authentication_providers" {
  description = "Authentication providers for the Grafana workspace. Valid values are AWS_SSO, SAML, or both"
  type        = list(string)
  default     = ["AWS_SSO"]
}

variable "grafana_data_sources" {
  description = "AWS data sources to enable in the Grafana workspace"
  type        = list(string)
  default     = ["PROMETHEUS"]
}

variable "grafana_network_access_control" {
  description = "Network access control configuration for the Grafana workspace"
  type        = any
  default     = {}
}

variable "grafana_role_associations" {
  description = "Map of Grafana workspace roles to IAM Identity Center user/group IDs"
  type        = any
  default     = {}
}

variable "associate_license" {
  description = "Whether to associate a Grafana Enterprise license with the workspace"
  type        = bool
  default     = false
}

