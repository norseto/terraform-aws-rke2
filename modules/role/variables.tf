variable "name" {
  description = "name. Will be used same name for policy/role/instance profile."
  type        = string
}

variable "use_name_prefix" {
  description = "if true, suffixes will be added."
  type        = bool
  default     = false
}

variable "role_path" {
  description = "role path."
  type        = string
  default     = "/ec2/"
}

variable "policies" {
  description = "role policies."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.policies) <= 18
    error_message = "The policy must be no more than 18 items"
  }
}

variable "permissions_boundary" {
  description = "permissions boundary policy ARN"
  type        = string
  default     = ""
}

variable "description" {
  description = "description"
  type        = string
  default     = ""
}

variable "tags" {
  description = "tags."
  type        = map(string)
  default     = {}
}

variable "create_spotfleet_role" {
  description = "true if spot fleet role creation."
  type        = bool
  default     = false
}
