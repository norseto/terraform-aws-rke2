locals {
  prefix = var.prefix

  iam_instance_profile_arn = var.iam_instance_profile_arn

  pools = var.pools
  fleet_pools = local.use_asg ? [] : [
    for p in local.pools : merge(p, {
      fleet_size : local.single ? 1 : try(p.desired_capacity, try(p.max_size, try(p.min_size, 1)))
      requirements : length(p.instance_types) > 0 ? setproduct(local.subnet_ids, p.instance_types) : []
    })
  ]

  instance_ami = local.ami_dict[var.os_type]

  ssh_key_name   = var.ssh_key_name
  extra_ssh_keys = var.extra_ssh_keys

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  allocate_public_ip = var.allocate_public_ip

  user_data         = var.user_data
  target_group_arns = var.target_group_arns

  use_asg = var.use_asg
  single  = var.single

  tags = var.tags

  fleet_strategy_dict_spot = {
    lowest-price : "lowestPrice"
    diversified : "diversified"
    capacity-optimized : "capacityOptimized"
    capacity-optimized-prioritized : "capacityOptimizedPrioritized"
  }
  fleet_strategy_dict_on_demand = {
    lowest-price : "lowestPrice"
    diversified : "prioritized"
    capacity-optimized : "prioritized"
    capacity-optimized-prioritized : "prioritized"
  }
  asg_strategy_dict_spot = merge(local.fleet_strategy_dict_spot, {
    lowest-price : "lowest-price"
    diversified : "price-capacity-optimized"
    price-capacity-optimized : "price-capacity-optimized"
    capacity-optimized : "capacity-optimized"
    capacity-optimized-prioritized : "capacity-optimized-prioritized"
  })
  asg_strategy_dict_on_demand = {
    lowest-price : "lowest-price"
    diversified : "prioritized"
    capacity-optimized : "prioritized"
    capacity-optimized-prioritized : "prioritized"
  }

  ami_dict = {
    Ubuntu : data.aws_ami.this.id
    openSUSE : data.aws_ami.openSUSE.id
  }
}
