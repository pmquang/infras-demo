output "iam_user" {
  value = "${aws_iam_user.this_user.name}"
}

output "user_access_key" {
  value = "${aws_iam_access_key.this_access_key.id}"
}

output "user_secret_key" {
  value = "${aws_iam_access_key.this_access_key.encrypted_secret}"
}
