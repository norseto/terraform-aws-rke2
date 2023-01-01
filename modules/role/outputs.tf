output "aws_iam_instance_profile" {
  description = "iam instance profile object"
  value       = aws_iam_instance_profile.this
}

output "aws_iam_role" {
  description = "iam role object"
  value       = aws_iam_role.this
}
