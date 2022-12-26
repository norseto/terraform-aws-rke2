variable "bucket_id" {
  description = "bucket id"
  type        = string
}

variable "bucket_region" {
  description = "bucket region"
  type        = string
}

variable "versioning" {
  description = "enable versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "tags."
  type        = map(string)
  default     = {}
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
