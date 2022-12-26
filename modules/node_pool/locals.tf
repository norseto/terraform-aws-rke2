locals {
  prefix = var.prefix

  iam_instance_profile_arn = var.iam_instance_profile_arn

  pools = var.pools
  spot_pools = [
    for p in local.pools : merge(p, {
      fleet_size : local.single ? 1 : try(p.desired_capacity, try(p.max_size, try(p.min_size, 1)))
      requirements : length(p.instance_types) > 0 ? setproduct(local.subnet_ids, p.instance_types) : []
      alt_requirements : length(p.instance_types) > 0 ? [] : local.subnet_ids
    })
    if !local.use_asg && try(p.instances_distribution.spot_max_price, null) != null
  ]
  ondemand_pool = [
    for p in local.pools : merge(p, {
      fleet_size : local.single ? 1 : try(p.desired_capacity, try(p.max_size, try(p.min_size, 1)))
      requirements : length(p.instance_types) > 0 ? setproduct(local.subnet_ids, p.instance_types) : []
      alt_requirements : length(p.instance_types) > 0 ? [] : local.subnet_ids
    })
    if !local.use_asg && try(p.instances_distribution.spot_max_price, null) == null
  ]

  instance_ami = data.aws_ami.this.id

  ssh_key_name   = var.ssh_key_name
  extra_ssh_keys = var.extra_ssh_keys

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  allocate_public_ip = var.allocate_public_ip

  user_data         = var.user_data
  target_group_arns = var.target_group_arns

  use_asg             = var.use_asg
  single              = var.single
  spot_fleet_role_arn = var.spot_fleet_role_arn

  tags = var.tags

  strategy_dict = {
    lowest-price : "lowestPrice"
    diversified : "diversified"
    capacity-optimized : "capacityOptimized"
    capacity-optimized-prioritized : "capacityOptimizedPrioritized"
  }
  strategy_dict_on_demand = {
    lowest-price : "lowestPrice"
    diversified : "prioritized"
    capacity-optimized : "prioritized"
    capacity-optimized-prioritized : "prioritized"
  }
}
