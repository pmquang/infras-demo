output "this_iam_role" {
  description = "The name of IAM role"
  value = aws_iam_role.this.id
}

output "this_iam_role_arn" {
  description = "The name of IAM role"
  value = aws_iam_role.this.arn
}

output "iam_instance_profile_name" {
  value = var.iam_instance_profile == "true" ? aws_iam_instance_profile.this[0].name : ""
}
