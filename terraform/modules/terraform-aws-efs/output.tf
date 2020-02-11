output "dns_name" {
  description = "The DNS name of the EFS"
  value       = aws_efs_file_system.this-efs-file-system.dns_name
}
