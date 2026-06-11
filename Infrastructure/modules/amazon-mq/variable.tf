variable "engine_type" {
  type        = string
  description = "The broker's engine type (e.g. ActiveMQ)."
  default     = "ActiveMQ"
}

variable "engine_version" {
  type        = string
  description = "The version of the broker engine."
  default     = "5.19"
}

variable "host_instance_type" {
  type        = string
  description = "The broker's instance type. e.g. mq.t2.micro or mq.m4.large"
  default     = "mq.t3.micro"
}

variable "allowed_ingress_ports" {
  type        = list(number)
  description = <<-EOT
    List of TCP ports to allow access to in the created security group.
    Default is to allow access to all ports. Set `create_security_group` to `false` to disable.
    Note: List of ports must be known at "plan" time.
    EOT
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the broker is deployed into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to deploy the broker into (one for SINGLE_INSTANCE)"
}

variable "project_name" {
  type        = string
  description = "Project name, used for tagging"
}

variable "mq_admin_user" {
  type        = list(string)
  description = "Admin username. If empty, the module generates one. Password is auto-generated and stored in SSM."
  default     = []
}

variable "mq_application_user" {
  type        = list(string)
  description = "Application username used by the apps. If empty, the module generates one. Password is auto-generated and stored in SSM."
  default     = []
}
