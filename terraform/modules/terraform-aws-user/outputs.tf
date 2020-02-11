output "iam_user" {
  value = "${aws_iam_user.user.name}"
}

output "user_password" {
  value = "${aws_iam_user_login_profile.login-profile.encrypted_password}"
}

output "user_access_key" {
  value = "${aws_iam_access_key.access_key.id}"
}

output "user_secret_key" {
  value = "${aws_iam_access_key.access_key.encrypted_secret}"
}
