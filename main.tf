/**
 * # terraform-aws-rke2
 * Terraform module to buld a simple RKE2 cluster.
 * ## Basic type
 * Seed RKE2 server + server replica + Agents + 2NLB
 * ![Basic](images/basic.png)
 * ## Single type
 * Seed RKE2 server + Agents + EIP + Private Domain
 * ![Single](images/single.png)
 */

module "bucket" {
  source = "./modules/bucket"

  name   = local.base_name
  bucket = local.bucket_name
  tags   = local.tags

  versioning = false
}

module "configs" {
  source = "./modules/config"

  cluster_name           = local.base_name
  region                 = module.bucket.bucket.s3_bucket_region
  bucket_id              = module.bucket.bucket.s3_bucket_id
  token                  = local.token
  server_fqdn            = local.server_fqdn
  add_server_taint       = local.add_server_taint
  disabled_server_charts = local.disabled_server_charts
  tls_san                = local.tls_san
  rke2_version           = local.rke2_version
  api_endpoint           = local.api_endpoint
  cloud_config           = local.cloud_config
  addon_config           = local.addon_config

  tags = local.tags

  versioning = false
}

module "role_control_plane" {
  source = "./modules/role"

  name        = "${local.base_name}-control-plane"
  description = "Cluster control plane role"
  # TODO: merge capability
  policies = merge(
    local.server_policies
  )
}

module "role_agent" {
  source = "./modules/role"

  name        = "${local.base_name}-agent"
  description = "Cluster agent role"
  # TODO: merge capability
  policies = merge(
    local.agent_policies
  )
}

resource "aws_placement_group" "control_plane" {
  name            = "${local.base_name}-control-plane"
  strategy        = "partition"
  partition_count = length(local.control_plane.subnet_ids)
}

module "control_plane" {
  count  = length(local.replica_pools) > 0 ? 1 : 0
  source = "./modules/node_pool"

  prefix  = "${local.base_name}-"
  use_asg = !local.use_fleet_replica
  single  = false

  os_type      = local.os_type
  ssh_key_name = local.ssh_key_name
  security_group_ids = concat(local.control_plane.security_group_ids,
    [
      module.inter_cluster_sg.security_group_id,
      module.cluster_server_sg.security_group_id
  ])
  allocate_public_ip = local.use_eip ? true : local.control_plane.allocate_public_ip
  subnet_ids         = local.control_plane.subnet_ids
  pools              = local.replica_pools

  iam_instance_profile_arn = module.role_control_plane.aws_iam_instance_profile.arn

  user_data = base64encode(templatefile("${path.module}/userdata/control-plane-config.yaml", local.replacements))
  target_group_arns = local.use_eip ? [] : [
    aws_lb_target_group.cluster_server[0].arn,
    aws_lb_target_group.cluster_api[0].arn,
    aws_lb_target_group.kube_api[0].arn
  ]

  placement_group = aws_placement_group.control_plane.id

  tags = merge(local.tags, {
    ClusterName : local.base_name,
    Role : "control-plane-replica"
  })
}

module "control_plane_seed" {
  source = "./modules/node_pool"

  prefix  = "${local.base_name}-"
  use_asg = !local.use_fleet_seed
  single  = true

  os_type      = local.os_type
  ssh_key_name = local.ssh_key_name
  security_group_ids = concat(local.control_plane.security_group_ids,
    [
      module.inter_cluster_sg.security_group_id,
      module.cluster_server_sg.security_group_id
  ])
  allocate_public_ip = local.use_eip ? true : local.control_plane.allocate_public_ip
  subnet_ids         = local.control_plane.subnet_ids
  pools              = [local.seed_pool]

  iam_instance_profile_arn = module.role_control_plane.aws_iam_instance_profile.arn

  user_data = base64encode(templatefile("${path.module}/userdata/control-plane-seed.yaml", local.replacements))

  target_group_arns = local.use_eip ? [] : [
    aws_lb_target_group.cluster_server[0].arn,
    aws_lb_target_group.cluster_api[0].arn,
    aws_lb_target_group.kube_api[0].arn,
  ]

  placement_group = aws_placement_group.control_plane.id

  tags = merge(local.tags, {
    ClusterName : local.base_name,
    Role : "control-plane-seed"
  })
}

module "agent" {
  source = "./modules/node_pool"

  prefix  = "${local.base_name}-"
  use_asg = true
  single  = false

  os_type            = local.os_type
  ssh_key_name       = local.ssh_key_name
  security_group_ids = concat(local.agent.security_group_ids, [module.inter_cluster_sg.security_group_id])
  allocate_public_ip = local.use_eip ? true : local.agent.allocate_public_ip
  subnet_ids         = local.agent.subnet_ids
  pools              = local.agent.nodepools

  iam_instance_profile_arn = module.role_agent.aws_iam_instance_profile.arn

  user_data         = base64encode(templatefile("${path.module}/userdata/agent-config.yaml", local.replacements))
  target_group_arns = local.agent.target_group_arns

  tags = merge(local.tags, {
    ClusterName : local.base_name
    Role : "agent"
  })
}
