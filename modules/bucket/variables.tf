variable "bucket" {
  description = "bucket name"
  type        = string
  default     = ""
}

variable "name" {
  description = "base name."
  type        = string
}

variable "versioning" {
  description = "enable versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "tags"
  type        = map(string)
  default     = {}
}

