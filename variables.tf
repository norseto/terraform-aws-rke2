variable "prefix" {
  description = "name prefix"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "cluster name"
  type        = string
}

variable "bucket_name" {
  description = "backupt bucket name"
  type        = string
  default     = ""
}

variable "token" {
  description = "server token"
  type        = string
  default     = ""
}

variable "server_fqdn" {
  description = "server fqdn"
  type        = string
  default     = ""
}

variable "tls_san" {
  description = "tls sans"
  type        = list(string)
  default     = []
}

variable "ssh_key_name" {
  description = "instance ssh key name"
  type        = string
  default     = ""
}

variable "extra_ssh_keys" {
  description = "extra ssh keys"
  type        = list(string)
  default     = []
}

variable "api_endpoint_ip_white_list" {
  description = "CIDR blocks that can access to control plane"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_endpoint_subnet_ids" {
  description = "subnets for loadbalancer to controller kube API"
  type        = list(string)
}

# You can't use one of the following instance
# types: C1, CC1, CC2, CG1, CG2, CR1, G1, G2, HI1, HS1, M1, M2, M3, or T1.
variable "control_plane" {
  description = "control plane configurations"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
    allocate_public_ip = bool
    policy             = optional(map(string), {})
    # Single instance uses EIP
    single = optional(bool, false)
    nodepools = list(object({
      # TODO: Allow subnet IDs to be specified.
      name                   = string
      size                   = number
      volume_size            = optional(number, 20)
      instance_types         = list(string)
      instances_distribution = any
      cpu_credits            = optional(string)
    }))
  })
}

# You can't use one of the following instance
# types: C1, CC1, CC2, CG1, CG2, CR1, G1, G2, HI1, HS1, M1, M2, M3, or T1.
variable "agent" {
  description = "control plane configurations"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
    allocate_public_ip = bool
    policy             = optional(map(string), {})
    target_group_arns  = optional(list(string), [])
    nodepools = list(object({
      name             = string
      min_size         = optional(number, 1)
      max_size         = optional(number, 3)
      desired_capacity = optional(number, 3)
      instance_types   = optional(list(string), ["t3.medium"])
      volume_size      = optional(number, 20)
      cpu_credits      = optional(string)

      ignore_desired_capacity_changes = optional(bool, true)

      instances_distribution = object({
        on_demand_base_capacity                  = optional(number)
        on_demand_allocation_strategy            = optional(string)
        on_demand_percentage_above_base_capacity = optional(number)
        spot_allocation_strategy                 = optional(string)
        spot_max_price                           = optional(string)
      })
    }))
  })
}

variable "rke2_version" {
  description = "REK2 version like 'v1.20.8+rke2r1'"
  type        = string
  default     = ""
}

variable "add_server_taint" {
  description = <<EOD
    True if add server taint.
    Note: The NGINX Ingress and Metrics Server addons will not be deployed
    when all nodes are tainted with CriticalAddonsOnly.
    If your server nodes are so tainted, these addons will remain pending
    until untainted agent nodes are added to the cluster.
  EOD
  type        = bool
  default     = false
}

variable "disabled_server_charts" {
  description = "Specify disabled server charts ammong rke2-canal, rke2-coredns, rke2-ingress-nginx, rke2-metrics-server"
  type        = list(string)
  default     = []
}

variable "internal_zone_id" {
  description = <<EOD
    Private Route53 zone id to register server node(s) when control_plane.single is true.
    Zone sholud be associated with vpc
  EOD
  type        = string
  default     = null
}
