locals {
  name   = var.name
  bucket = length(var.bucket) > 0 ? var.bucket : local.name

  read_write_policy = "${local.name}-read-write-policy"
  read_only_policy  = "${local.name}-read-only-policy"

  versioning = var.versioning
  tags       = var.tags

  backup_prefix         = var.backup_prefix
  backup_retention_days = var.backup_retention_days
}
