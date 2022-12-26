data "aws_iam_policy_document" "spotfleet" {
  statement {
    sid     = "SpotAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "spotfleet" {
  count = local.create_spotfleet_role ? 1 : 0

  name        = local.spot_role_name
  description = "Spot instance fleet role"

  assume_role_policy    = data.aws_iam_policy_document.spotfleet.json
  force_detach_policies = true

  tags = merge(
    { Name : local.spot_role_name },
    local.tags
  )
}

resource "aws_iam_role_policy_attachment" "spotfleet" {
  count = local.create_spotfleet_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
  role       = aws_iam_role.spotfleet[0].name
}
