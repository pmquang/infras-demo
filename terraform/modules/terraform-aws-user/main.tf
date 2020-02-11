## Group enfore-mfa
data "template_file" "enforce-mfa" {
  template = "${file("${path.module}/data/enforce-mfa-policy.json")}"

  vars = {
    account_id = var.account_id
  }
}

resource "aws_iam_policy" "enforce-mfa" {
  name   = "${var.username}-enforce-mfa"
  policy = "${data.template_file.enforce-mfa.rendered}"
}

resource "aws_iam_group" "enforce-mfa" {
  name = "${var.username}-enforce-mfa"
}

resource "aws_iam_group_policy_attachment" "enforce-mfa" {
  group      = "${aws_iam_group.enforce-mfa.name}"
  policy_arn = "${aws_iam_policy.enforce-mfa.arn}"
}

## IAM user
resource "aws_iam_user" "user" {
  name          = var.username
  force_destroy = true
}

resource "aws_iam_access_key" "access_key" {
  user    = aws_iam_user.user.name
  pgp_key = var.gpg_key
}

resource "aws_iam_user_login_profile" "login-profile" {
  user = aws_iam_user.user.name

  pgp_key                 = var.gpg_key
  password_reset_required = true
}

resource "aws_iam_user_group_membership" "user-membership" {
  user = aws_iam_user.user.name

  groups = [
    aws_iam_group.enforce-mfa.name
  ]
}
