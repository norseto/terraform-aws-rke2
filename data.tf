data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "vpc" {
  id = local.vpc_id
}

resource "random_string" "token" {
  count = length(local.config_token) > 0 ? 0 : 1

  length           = 256
  special          = true
  override_special = "/-=!?"
}