locals {
  globals  = yamldecode(file("${find_in_parent_folders("globals.yaml")}"))
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env_name = local.env_vars.locals.env
  prefix   = length(local.env_name) > 0 ? "${local.env_name}-" : ""

  source_base_url = "tfr:///terraform-aws-modules/vpc/aws"

  vpc = merge(
    local.globals.vpc,
    { name = "${local.prefix}${local.globals.vpc.name}" }
  )
}


terraform {
  source = "${local.source_base_url}?version=3.14.2"
}

inputs = merge(
  local.vpc
)
