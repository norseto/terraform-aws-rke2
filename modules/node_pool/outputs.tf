output "autoscaling_group_ids" {
  description = "List of id of autoscaling group generated"
  value       = [for p in module.node_pool : p.autoscaling_group_id]
}

output "autoscaling_group_arns" {
  description = "List of arn of autoscaling group generated"
  value       = [for p in module.node_pool : p.autoscaling_group_arn]
}

output "autoscaling_group_names" {
  description = "List of name of autoscaling group generated"
  value       = [for p in module.node_pool : p.autoscaling_group_name]
}
