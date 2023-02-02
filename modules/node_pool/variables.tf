variable "prefix" {
  description = "prefix"
  type        = string
  default     = ""
}

variable "instance_types" {
  description = "default instance type"
  type        = list(string)
  default     = ["t3a.medium"]
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

variable "security_group_ids" {
  description = "security groups"
  type        = list(string)
  default     = []
}

variable "allocate_public_ip" {
  description = "allocate public IP"
  type        = bool
  default     = true
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "subnet ids"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_arn" {
  description = "IAM instance profile arn"
  type        = string
}

variable "user_data" {
  description = "user data"
  type        = string
  default     = ""
}

variable "target_group_arns" {
  description = "loadbalancer target groups for control plane"
  type        = list(string)
  default     = []
}

variable "use_asg" {
  description = "true if asg should be used. true for agent servers, false for control planes."
  type        = bool
  default     = false
}

variable "single" {
  description = "true if should be a single node. it is used when use_asg is false. true for seed control plane."
  type        = bool
  default     = false
}

variable "pools" {
  description = "node pool configurations."
  type = list(object({
    name = string
    # 1 will be used for seed control plane, desired for other control plane.
    min_size         = number
    max_size         = number
    desired_capacity = number
    instance_types   = list(string)
    cpu_credits      = optional(string, "standard")
    volume_size      = optional(number, 20)

    ignore_desired_capacity_changes = optional(bool, true)

    # For control plane, spot will be used when spot_max_price is set.
    instances_distribution = object({
      on_demand_base_capacity                  = optional(number)
      on_demand_allocation_strategy            = optional(string)
      on_demand_percentage_above_base_capacity = optional(number)
      spot_allocation_strategy                 = optional(string)
      spot_max_price                           = optional(string)
    })
  }))
}

variable "placement_group" {
  description = "The name of the placement group into which you'll launch your instances, if any"
  type        = string
  default     = null
}
