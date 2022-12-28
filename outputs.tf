output "agent_autoscaling_group_ids" {
  description = "List of agent's Autoscaling group ID"
  value       = module.agent.autoscaling_group_ids
}
output "agent_autoscaling_group_arns" {
  description = "List of arn of autoscaling group generated"
  value       = module.agent.autoscaling_group_arns
}
