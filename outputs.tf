output "agent_autoscaling_group_ids" {
  description = "List of agent's Autoscaling group ID"
  value       = module.agent.autoscaling_group_ids
}
output "agent_autoscaling_group_arns" {
  description = "List of arn of autoscaling group generated"
  value       = module.agent.autoscaling_group_arns
}
output "ec2_fleet_ids" {
  description = "List of id of ec2 fleet generated"
  value       = concat(try(module.control_plane[0].ec2_fleet_ids, []), module.control_plane_seed.ec2_fleet_ids)
}

output "ec2_fleet_arns" {
  description = "List of arn of ec2 fleet generated"
  value       = concat(try(module.control_plane[0].ec2_fleet_arns, []), module.control_plane_seed.ec2_fleet_arns)
}
