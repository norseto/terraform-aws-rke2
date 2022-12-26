resource "aws_eip" "seed" {
  count = local.use_eip ? 1 : 0

  vpc = true
  tags = merge(local.tags, {
    Name : "${local.base_name}-seedeip"
  })
}

resource "aws_iam_policy" "eip_associate_policy" {
  count = local.use_eip ? 1 : 0

  name        = "${local.base_name}-seedeip-policy"
  path        = "/"
  description = "Policy for EIP assosiation"

  policy = data.aws_iam_policy_document.seed_eip[0].json
}

data "aws_iam_policy_document" "seed_eip" {
  count = local.use_eip ? 1 : 0

  statement {
    sid = "1"

    actions = [
      "ec2:DisassociateAddress",
      "ec2:AssociateAddress"
    ]

    resources = [
      "arn:aws:ec2:*:*:elastic-ip/${aws_eip.seed[0].id}",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:network-interface/*"
    ]
  }

  statement {
    sid = "2"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = [
      aws_route53_zone.private[0].arn
    ]
  }
}

resource "aws_route53_zone" "private" {
  count = local.use_eip ? 1 : 0

  name = local.seed_priv_domain

  vpc {
    vpc_id = local.vpc_id
  }
  tags = local.tags
}

resource "aws_route53_record" "seed" {
  count = local.use_eip ? 1 : 0

  name    = local.seed_priv_dns
  zone_id = aws_route53_zone.private[0].zone_id
  type    = "A"
  ttl     = 300
  records = ["10.0.0.1"]

  lifecycle {
    ignore_changes = [
      records, ttl
    ]
  }
}
