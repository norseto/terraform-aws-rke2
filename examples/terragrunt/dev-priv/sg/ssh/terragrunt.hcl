include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${get_terragrunt_dir()}/../../../_env/sg/ssh.hcl"
  expose = true
}
