resource "aws_ec2_fleet" "this" {
  for_each = { for p in local.ondemand_pool : p.name => p if p.fleet_size > 0 }

  target_capacity_specification {
    default_target_capacity_type = "on-demand"
    total_target_capacity        = each.value.fleet_size
  }

  on_demand_options {
    allocation_strategy = try(local.strategy_dict_on_demand[each.value.instances_distribution.on_demand_allocation_strategy], "lowestPrice")
  }

  # target_group_arns = local.target_group_arns

  launch_template_config {
    launch_template_specification {
      launch_template_id = module.node_pool[each.key].launch_template_id
      version            = module.node_pool[each.key].launch_template_latest_version
    }
    dynamic "override" {
      for_each = each.value.requirements
      content {
        subnet_id     = override.value[0]
        instance_type = override.value[1]
      }
    }
  }

  tags = merge(local.tags, {
    Name : "${local.prefix}${each.key}"
  })
}
