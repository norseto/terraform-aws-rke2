locals {
  account_id  = data.aws_caller_identity.current.account_id
  region_name = data.aws_region.current.name

  prefix       = length(var.prefix) > 0 ? "${var.prefix}-" : ""
  vpc_id       = var.vpc_id
  cluster_name = var.cluster_name
  base_name    = "${local.prefix}${var.cluster_name}"

  vpc_cidr = data.aws_vpc.vpc.cidr_block

  # Private Zone ID for internal seed DNS
  internal_zone_id  = var.internal_zone_id
  internal_zone_arn = try(data.aws_route53_zone.private[0].arn, aws_route53_zone.private[0].arn)

  # Config
  bucket_name  = length(var.bucket_name) > 0 ? var.bucket_name : "${local.base_name}-${local.account_id}-${local.region_name}"
  config_token = var.token == null ? "" : var.token
  token        = try(random_string.token[0].result, local.config_token)

  use_eip      = local.control_plane.single
  seed_eip     = local.use_eip ? aws_eip.seed[0] : null
  seed_eip_pub = local.use_eip ? local.seed_eip.public_ip : null

  seed_eip_dns = local.use_eip ? format("ec2-%s.%s.compute.amazonaws.com",
  replace(local.seed_eip_pub, ".", "-"), local.region_name) : null

  seed_priv_domain = try(data.aws_route53_zone.private[0].name, "${local.prefix}${var.cluster_name}.private")
  seed_priv_host   = "seed-${local.prefix}${var.cluster_name}"
  seed_priv_dns    = "${local.seed_priv_host}.${local.seed_priv_domain}"

  api_endpoint = local.use_eip ? local.seed_eip_dns : aws_lb.api_nlb[0].dns_name
  server_fqdn  = local.use_eip ? local.seed_priv_dns : aws_lb.cluster_nlb[0].dns_name

  tls_san = concat(var.tls_san == null ? [] : var.tls_san, var.server_fqdn == null ? [] : [var.server_fqdn], [local.api_endpoint])

  ssh_key_name   = var.ssh_key_name
  extra_ssh_keys = var.extra_ssh_keys

  # Control Plane
  control_plane = merge(var.control_plane, { ssh_key_name : local.ssh_key_name })

  # Use EC2Fleet for control planes.
  use_fleet_seed    = false
  use_fleet_replica = false

  # Control Plane Pools - Separate first server(seed) and others.
  server_pools = [
    for p in local.control_plane.nodepools :
    merge(p, { min_size : p.size, max_size : p.size, desired_capacity : p.size })
  ]
  seed_pool     = merge(local.server_pools[0], { max_size : 1, min_size : 1, desired_capacity : 1 })
  replica_pools = length(local.server_pools) > 1 ? slice(local.server_pools, 1, length(local.server_pools)) : []

  addon_config = var.addons
  ebs_policy = local.addon_config.aws_ebs_csi_driver == "none" ? {} : {
    ebs-csi-driver : "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  addon_policy = merge(local.ebs_policy)

  agent_policies = merge(
    local.agent.policy, local.addon_policy,
    { s3bucket-policy : module.bucket.read_only_policy.arn }
  )
  server_policies = merge(
    local.control_plane.policy, local.addon_policy,
    {
      AmazonEC2ReadOnlyAccess : "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
      s3bucket-policy : module.bucket.read_write_policy.arn
      restore-policy : module.restore_policy.arn
    },
    local.use_eip ? {
      eip-policy : aws_iam_policy.eip_associate_policy[0].arn
      } : {
      targetgroup-policy : aws_iam_policy.targetgroup_register_policy[0].arn
    }
  )

  # Agent
  agent = merge(var.agent, { ssh_key_name : local.ssh_key_name })

  # Control Plane accessibility configurations.
  api_endpoint_ip_white_list = var.api_endpoint_ip_white_list
  api_endpoint_subnet_ids    = var.api_endpoint_subnet_ids

  # RKE2 version
  rke2_version = length(var.rke2_version) > 0 ? "INSTALL_RKE2_VERSION=\"${var.rke2_version}\"" : ""
  tags         = merge(var.tags, { ClusterName : "${local.prefix}${var.cluster_name}" })

  # File replacements
  replacements = {
    extra_ssh_keys : local.extra_ssh_keys
    bucket : module.bucket.bucket.s3_bucket_id
    server : local.server_fqdn
    os_type : local.os_type
    startup : local.startup
  }

  cloud_config = {
    eip_allocation_id : try(local.seed_eip.id, "")
    zone_id : try(aws_route53_zone.private[0].id, try(data.aws_route53_zone.private[0].id, ""))
    api_tg_arn : local.use_eip ? "" : aws_lb_target_group.kube_api[0].arn
    in_api_tg_arn : local.use_eip ? "" : aws_lb_target_group.cluster_api[0].arn
    in_srv_tg_arn : local.use_eip ? "" : aws_lb_target_group.cluster_server[0].arn
  }

  # Server taints
  add_server_taint = var.add_server_taint
  # Disabled charts
  disabled_server_charts = var.disabled_server_charts

  # For Events
  asg_groupnames = concat(
    module.control_plane_seed.autoscaling_group_names,
    try(module.control_plane[0].autoscaling_group_names, []),
    module.agent.autoscaling_group_names
  )
  event_bus = true

  # For OS variation
  os_type = var.os_type
  startup = var.startup
}
