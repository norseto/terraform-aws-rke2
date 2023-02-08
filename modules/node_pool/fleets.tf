resource "aws_ec2_fleet" "this" {
  for_each = { for p in local.fleet_pools : p.name => p if p.fleet_size > 0 }

  target_capacity_specification {
    default_target_capacity_type = each.value.instances_distribution.spot_max_price == null ? "on-demand" : "spot"
    total_target_capacity        = each.value.fleet_size
  }

  on_demand_options {
    allocation_strategy = try(local.strategy_dict_on_demand[each.value.instances_distribution.on_demand_allocation_strategy], "lowestPrice")
  }

  spot_options {
    instance_interruption_behavior = "stop"
    allocation_strategy            = try(local.strategy_dict[each.value.instances_distribution.spot_allocation_strategy], "lowestPrice")
  }

  terminate_instances = true

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
        max_price     = try(each.value.instances_distribution.spot_max_price, null)
      }
    }
  }

  tags = merge(local.tags, {
    Name : "${local.prefix}${each.key}"
  })
}

# resource "aws_ec2_fleet" "spot" {
#   for_each = { for p in local.spot_pools : p.name => p if p.fleet_size > 0 }

#   target_capacity_specification {
#     default_target_capacity_type = "spot"
#     total_target_capacity        = each.value.fleet_size
#   }

#   spot_options {
#     instance_interruption_behavior = "stop"
#     allocation_strategy            = try(local.strategy_dict[each.value.instances_distribution.spot_allocation_strategy], "lowestPrice")
#   }

#   terminate_instances = true

#   launch_template_config {
#     launch_template_specification {
#       launch_template_id = module.node_pool[each.key].launch_template_id
#       version            = module.node_pool[each.key].launch_template_latest_version
#     }
#     dynamic "override" {
#       for_each = each.value.requirements
#       content {
#         subnet_id     = override.value[0]
#         instance_type = override.value[1]
#         max_price     = each.value.instances_distribution.spot_max_price
#       }
#     }
#   }

#   tags = merge(local.tags, {
#     Name : "${local.prefix}${each.key}"
#   })
# }
