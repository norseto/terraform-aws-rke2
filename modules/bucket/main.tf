/**
 * # bucket
 * Create S3 bucket that contents in/out.
 */

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.6.0"

  bucket = local.bucket
  acl    = "private"

  versioning = {
    enabled = local.versioning
  }

  tags = merge(local.tags, {
    Name : local.bucket
    Cluster : local.name
  })
}

data "aws_iam_policy_document" "read_write" {
  statement {
    actions = [
      "s3:*",
      "s3-object-lambda:*"
    ]

    resources = [
      module.bucket.s3_bucket_arn,
      "${module.bucket.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "read_only" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3-object-lambda:Get*",
      "s3-object-lambda:List*"
    ]

    resources = [
      module.bucket.s3_bucket_arn,
      "${module.bucket.s3_bucket_arn}/*"
    ]
  }
}


module "read_write_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.0"

  name   = local.read_write_policy
  policy = data.aws_iam_policy_document.read_write.json

  tags = {
    Name : local.read_write_policy
    Cluster : local.name
  }
}

module "read_only_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.0"

  name   = local.read_only_policy
  policy = data.aws_iam_policy_document.read_only.json

  tags = merge(local.tags, {
    Name : local.read_only_policy
    Cluster : local.name
  })
}
