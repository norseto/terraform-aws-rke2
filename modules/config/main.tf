resource "aws_s3_object" "configs" {
  for_each = { for c in local.configs : c.name => c if !c.empty }

  key    = "config/${each.value.name}"
  bucket = local.bucket_id

  content_type   = each.value.content_type
  content_base64 = base64encode(templatefile("${path.module}/files/${each.value.name}", local.replacements))

  force_destroy = local.versioning
  tags          = local.tags
}

resource "aws_s3_object" "dummies" {
  for_each = { for c in local.configs : c.name => c if c.empty }

  key    = "config/${each.value.name}"
  bucket = local.bucket_id

  content_type   = each.value.content_type
  content_base64 = "Cg=="

  force_destroy = local.versioning
  tags          = local.tags

  lifecycle {
    ignore_changes = [
      content_type, content_base64, tags, tags_all
    ]
  }
}
