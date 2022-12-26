output "bucket" {
  description = "bucket"
  value       = module.bucket
}

output "read_write_policy" {
  description = "bucket read-write policy"
  value       = module.read_write_policy
}

output "read_only_policy" {
  description = "bucket read-only policy"
  value       = module.read_only_policy
}
