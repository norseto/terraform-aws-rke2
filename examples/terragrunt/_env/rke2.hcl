locals {
  rkeconfig = yamldecode(file("${find_in_parent_folders("rke2.yaml")}"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env_name  = local.env_vars.locals.env

  source_base_url = "${get_terragrunt_dir()}/../../../..//"

  cluster = merge(
    local.rkeconfig.rke-cluster,
    {
      prefix = "${local.env_name}"
    }
  )
}

dependency "vpc" {
  config_path = "${get_original_terragrunt_dir()}/../vpc"
}

dependency "ssh_sg" {
  config_path = "${get_original_terragrunt_dir()}/../sg/ssh"
}

terraform {
  source = "${local.source_base_url}"
}

inputs = merge(
  local.cluster,
  {
    vpc_id : dependency.vpc.outputs.vpc_id,
    api_endpoint_subnet_ids : dependency.vpc.outputs.public_subnets,
    control_plane : merge(local.cluster.control_plane, {
      security_group_ids : [
        dependency.ssh_sg.outputs.security_group_id,
      ],
      subnet_ids : dependency.vpc.outputs.public_subnets
    }),
    agent : merge(local.cluster.agent, {
      security_group_ids : [
        dependency.ssh_sg.outputs.security_group_id,
      ],
      subnet_ids : dependency.vpc.outputs.public_subnets
    })
  }
)
