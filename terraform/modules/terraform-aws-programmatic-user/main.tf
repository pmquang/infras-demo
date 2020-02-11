## IAM user
resource "aws_iam_user" "this_user" {
  name          = var.username
  force_destroy = true
}

resource "aws_iam_access_key" "this_access_key" {
  user    = aws_iam_user.this_user.name
  pgp_key = var.gpg_key
}

resource "aws_iam_user_policy" "this_iam_user_policy" {
  name = var.username
  user = "${aws_iam_user.this_user.name}"

  policy = var.policy
}
