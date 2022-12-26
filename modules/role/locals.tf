locals {
  suffixes     = var.use_name_prefix
  base_name    = var.name
  policy_name  = local.suffixes ? "${local.base_name}-policy" : local.base_name
  role_name    = local.suffixes ? "${local.base_name}-role" : local.base_name
  profile_name = local.suffixes ? "${local.base_name}-profile" : local.base_name
  role_path    = var.role_path

  spot_role_name        = local.suffixes ? "${local.base_name}-spotfleet" : "${local.base_name}-spotfleet"
  create_spotfleet_role = var.create_spotfleet_role

  permissions_boundary = var.permissions_boundary
  description          = var.description

  min_policies = {
    AmazonSSMManagedInstanceCore : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonEC2ContainerRegistryReadOnly : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
  policies = merge(
    local.min_policies,
    var.policies
  )
  tags = var.tags
}
