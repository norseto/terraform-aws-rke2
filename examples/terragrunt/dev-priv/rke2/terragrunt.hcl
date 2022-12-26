include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${get_terragrunt_dir()}/../../_env/rke2.hcl"
  expose = true
}

inputs = merge(include.env.inputs, {
  control_plane: merge(include.env.inputs.control_plane, {
    subnet_ids : dependency.vpc.outputs.private_subnets
  }),
  agent: merge(include.env.inputs.agent, {
    subnet_ids : dependency.vpc.outputs.private_subnets
  }),
})
