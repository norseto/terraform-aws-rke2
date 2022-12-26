data "aws_partition" "current" {}
data "aws_default_tags" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = local.role_name
  path        = local.role_path
  description = local.description

  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
  permissions_boundary  = local.permissions_boundary
  force_detach_policies = true

  tags = merge(
    { Name : local.role_name },
    local.tags
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.policies

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.this.name

  name = local.profile_name
  path = local.role_path

  tags = merge(
    { Name : local.profile_name },
    local.tags
  )
}

