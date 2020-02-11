module "jenkins-security-group" {

  source = "../../modules/terraform-aws-security-group"

  name = "${local.jenkins.name}-sg"
  vpc_id  = module.internal-vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule = "all-tcp"
      source_security_group_id = module.jenkins-security-group.this_security_group_id
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      source_security_group_id = module.jenkins-alb-security-group.this_security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "jenkins-alb-security-group" {

  source = "../../modules/terraform-aws-security-group"

  name = "${local.jenkins.name}-alb-sg"
  vpc_id  = module.internal-vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = "10.1.0.0/16"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "jenkins-ec2-iam-role" {
  source = "../../modules/terraform-aws-role"
  role_name   = "${local.jenkins.name}-ec2-iam"
  account_id = local.account_id
  iam_instance_profile = true
  custom_assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
POLICY
  policy_path = "${path.module}/data/policies/jenkins_ec2_iam_policy.json"
  tags = local.tags
}

module "jenkins-efs" {

  source = "../../modules/terraform-aws-efs"

  subnet_count = length(module.internal-vpc.private_subnets)
  subnets = module.internal-vpc.private_subnets
  security_groups = [module.jenkins-security-group.this_security_group_id]

  tags = merge(
    local.tags,
    {
      "Name" = "${local.jenkins.name}-efs"
    },
  )
}

data "template_file" "jenkins-launch-configuration" {

  template = "${file("${path.module}/data/launch-configs/aws_launch_config_jenkins.tpl")}"

  vars = {
    AWS_JENKINS_EFS_DNS_NAME       = module.jenkins-efs.dns_name
    AWS_JENKINS_MASTER_DOCKER_TAG  = local.jenkins.docker_tag
    AWS_JENKINS_MASTER_DOCKER_REPO = local.jenkins.docker_repo
    AWS_JENKINS_AWS_LOG_REGION     = local.jenkins.awslog_region
    AWS_JENKINS_AWS_LOG_GROUP      = local.jenkins.awslog_group
    AWS_JENKINS_AWS_LOG_STREAM     = local.jenkins.awslog_stream
  }

}

module "jenkins-iam-ecr-user" {
  source   = "../../modules/terraform-aws-programmatic-user"

  username = "jenkins-ecr"
  gpg_key  = "${file("${path.module}/data/credentials/gpg_key.pub")}"
  policy   = "${file("${path.module}/data/policies/jenkins_ecr_iam_policy.json")}"

}

module "jenkins-asg" {

  source = "../../modules/terraform-aws-autoscaling"
  name   = "${local.jenkins.name}"

  key_name        = aws_key_pair.ssh-key.id
  lc_name         = "${local.jenkins.name}-lc"
  image_id        = local.jenkins.image_id
  instance_type   = local.jenkins.instance_type
  security_groups = [module.jenkins-security-group.this_security_group_id]

  iam_instance_profile = module.jenkins-ec2-iam-role.iam_instance_profile_name

  root_block_device = [
    {
      volume_size = local.jenkins.root_volume_size
      volume_type = local.jenkins.root_volume_type
    },
  ]

  asg_name                  = "${local.jenkins.name}-asg"
  vpc_zone_identifier       = module.internal-vpc.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = local.jenkins.health_check_grace_period
  default_cooldown          = local.jenkins.default_cooldown
  min_size                  = local.jenkins.min_size
  max_size                  = local.jenkins.max_size
  desired_capacity          = local.jenkins.desired_capacity
  wait_for_capacity_timeout = 0

  target_group_arns         = module.jenkins-alb.target_group_arns

  #load_balancers           = [module.jenkins-alb.load_balancer_id]
  user_data                 = "${data.template_file.jenkins-launch-configuration.rendered}"
  tags_as_map               = local.tags
}

module "jenkins-alb" {
  source                    = "../../modules/terraform-aws-alb"
  load_balancer_name        = "${local.jenkins.name}-alb"
  load_balancer_is_internal = true
  idle_timeout              = 15
  security_groups           = [module.jenkins-alb-security-group.this_security_group_id]

  vpc_id                    = module.internal-vpc.vpc_id
  subnets                   = module.internal-vpc.private_subnets

  http_tcp_listeners_count = 1
  http_tcp_listeners = [
    {
      port               = 8080
      protocol           = "HTTP"
    },
  ]

  target_groups_count = 1
  target_groups = [
    {
      "name"                 = "${local.jenkins.name}-http"
      "backend_protocol"     = "HTTP"
      "backend_port"         = 8080
      "slow_start"           = 60
      "health_check_matcher" = "200-304"
      "deregistration_delay" = 10
      "stickiness_enabled"   = false
      "health_check_path"    = "/login"
    },
  ]

  logging_enabled        = false

  tags = merge(
    local.tags,
    {
      "Name" = "${local.jenkins.name}-alb"
    },
  )
}

output "jenkins-ecr-access-key" {
  value = module.jenkins-iam-ecr-user.user_access_key
}

output "jenkins-ecr-secret-key" {
  value = module.jenkins-iam-ecr-user.user_secret_key
}
