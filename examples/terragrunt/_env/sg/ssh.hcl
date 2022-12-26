locals {
  globals  = yamldecode(file("${find_in_parent_folders("globals.yaml")}"))
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env_name = local.env_vars.locals.env
  prefix   = length(local.env_name) > 0 ? "${local.env_name}-" : ""

  source_base_url = "tfr:///terraform-aws-modules/security-group/aws"

  target = local.globals.security_groups.ssh
  sg = merge(
    local.target,
    {
      name : "${local.prefix}${local.target.name}"
    }
  )
}

dependency "vpc" {
  config_path = "${get_original_terragrunt_dir()}/../../vpc"
}

terraform {
  source = "${local.source_base_url}?version=4.9.0"
}

inputs = merge(
  local.sg,
  { vpc_id : dependency.vpc.outputs.vpc_id }
)
