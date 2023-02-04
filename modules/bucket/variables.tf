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

variable "backup_prefix" {
  description = "etcd backup prefix"
  type        = string
  default     = "etcd-backup/"
}

variable "backup_retention_days" {
  description = "Retention days for etcd backups"
  type        = number
  default     = 30
}
