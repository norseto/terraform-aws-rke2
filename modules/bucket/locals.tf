locals {
  name   = var.name
  bucket = length(var.bucket) > 0 ? var.bucket : local.name

  read_write_policy = "${local.name}-read-write-policy"
  read_only_policy  = "${local.name}-read-only-policy"

  versioning = var.versioning
  tags       = var.tags
}
