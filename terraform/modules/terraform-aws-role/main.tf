locals {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account_id}:user/${var.username}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
POLICY
}

data "template_file" "this" {
  template = "${file("${var.policy_path}")}"
  vars = {
    username = var.username
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.role_name}-policy"
  policy = "${data.template_file.this.rendered}"
}

resource "aws_iam_role" "this" {
  name = "${var.role_name}-role"
  assume_role_policy = var.username != "" ? local.assume_role_policy : var.custom_assume_role_policy
  max_session_duration = 3600
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_instance_profile" "this" {
  count = var.iam_instance_profile == "true" ? 1 : 0
  name = "${var.role_name}-ec2-iam-instance-profile"
  role = aws_iam_role.this.name
}

