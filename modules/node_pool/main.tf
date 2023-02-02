/**
 * # node_pool
 * Creates
 * - Autoscaling Group for agent nodes
 * - (Spot)Fleet for the first control plane node(seed)
 * - (Spot)Fleet for the other control plane node
 */

module "node_pool" {
  for_each = { for p in local.pools : p.name => p }

  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.1"

  name = "${local.prefix}${each.key}"

  # Autoscaling group
  create             = local.use_asg
  use_name_prefix    = false
  min_size           = each.value.min_size
  max_size           = each.value.max_size
  desired_capacity   = each.value.desired_capacity
  capacity_rebalance = false

  ignore_desired_capacity_changes = each.value.ignore_desired_capacity_changes

  target_group_arns = local.target_group_arns

  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_allocation_strategy            = each.value.instances_distribution.on_demand_allocation_strategy
      on_demand_base_capacity                  = each.value.instances_distribution.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = each.value.instances_distribution.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = each.value.instances_distribution.spot_allocation_strategy
      spot_max_price                           = each.value.instances_distribution.spot_max_price
    }
    override = [
      for it in each.value.instance_types : {
        instance_type : it
        weighted_capacity : 1
      }
    ]
  }

  # Launch Template
  launch_template_use_name_prefix = false
  update_default_version          = true

  create_iam_instance_profile = false
  iam_instance_profile_arn    = local.iam_instance_profile_arn

  security_groups     = local.security_group_ids
  vpc_zone_identifier = local.subnet_ids

  image_id  = local.instance_ami
  key_name  = local.ssh_key_name
  user_data = local.user_data

  block_device_mappings = [
    {
      device_name : "/dev/sda1"
      ebs = {
        delete_on_termination : true
        encrypted : true
        volume_type : "gp2"
        volume_size : each.value.volume_size
      }
    }
  ]
  network_interfaces = [
    {
      delete_on_termination : true
      associate_public_ip_address : local.allocate_public_ip
      security_groups : []
    }
  ]

  # Set burstable instance to instance_type to avoid credit_specification is ignored.
  instance_type = length(
    [for t in each.value.instance_types : t if startswith(t, "t")]
  ) == length(each.value.instance_types) ? "t2.micro" : ""

  credit_specification = {
    cpu_credits = each.value.cpu_credits
  }

  tags = merge(local.tags, { PoolName : each.key, Name : "${local.prefix}${each.key}" })

  tag_specifications = [{
    resource_type = "instance"
    tags          = merge(local.tags, { PoolName : each.key, Name : "${local.prefix}${each.key}" })
  }]
}
