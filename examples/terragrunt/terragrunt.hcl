# Make the AWS region a reusable variable within the configuration
locals {
  aws_account_id = get_aws_account_id()
  config         = yamldecode(file("${find_in_parent_folders("config.yaml")}"))
  env_name       = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
  prefix         = length(local.env_name) > 0 ? "${local.env_name}-" : ""
}

#=========================================================
#  Remote Backend. Please Change for your needs.
#=========================================================
# AWS
remote_state {
  backend = "s3"
  config = {
    region         = local.config.aws.default_region
    bucket         = "${local.prefix}${local.config.aws.backend_bucket}-${local.aws_account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = "${local.prefix}${local.config.aws.backend_lock}-${local.aws_account_id}"
    encrypt        = true
  }
}

#=========================================================
#  Provider Generation. Please Change for your needs.
#=========================================================
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
#---------------------------------------------------------
# AWS
terraform {
  backend "s3" {}
}
provider "aws" {
  region  = "${local.config.aws.default_region}"
  default_tags {
    tags = {
      Environment = "${local.env_name}"
      Terraform = "true"
   }
  }
}
EOF
}

inputs = merge(
  {
    prefix : "${local.prefix}"
    aws_account_id : local.aws_account_id
  }
)
