
resource "aws_spot_fleet_request" "this" {
  for_each = { for p in local.spot_pools : p.name => p if p.fleet_size > 0 }

  iam_fleet_role  = local.spot_fleet_role_arn
  target_capacity = each.value.fleet_size

  instance_interruption_behaviour = "stop"
  spot_price                      = each.value.instances_distribution.spot_max_price
  allocation_strategy             = try(local.strategy_dict[each.value.instances_distribution.spot_allocation_strategy], "lowestPrice")
  on_demand_allocation_strategy   = try(local.strategy_dict_on_demand[each.value.instances_distribution.on_demand_allocation_strategy], "lowestPrice")

  target_group_arns = local.target_group_arns

  launch_template_config {
    launch_template_specification {
      id      = module.node_pool[each.key].launch_template_id
      version = module.node_pool[each.key].launch_template_latest_version
    }
    dynamic "overrides" {
      for_each = each.value.requirements
      content {
        subnet_id     = overrides.value[0]
        instance_type = overrides.value[1]
      }
    }
  }

  tags = merge(local.tags, {
    Name : "${local.prefix}${each.key}"
  })
}
