output "aws_iam_instance_profile" {
  description = "iam instance profile object"
  value       = aws_iam_instance_profile.this
}

output "aws_iam_role" {
  description = "iam role object"
  value       = aws_iam_role.this
}

output "spotfleet_iam_role" {
  description = "spotfleet iam role object"
  value       = try(aws_iam_role.spotfleet[0], {})
}
