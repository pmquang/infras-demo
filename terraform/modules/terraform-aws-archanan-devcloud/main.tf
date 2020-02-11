module "mpi-cluster-vpc" {

  source = "../terraform-aws-vpc"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = [cidrsubnet(var.vpc_cidr,2,0),cidrsubnet(var.vpc_cidr,2,1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr,2,2),cidrsubnet(var.vpc_cidr,2,3)]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    Type = "private"
  }

  public_subnet_tags = {
    Type = "public"
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

module "mpi-cluster-security-group" {
  source = "../terraform-aws-security-group"

  name = var.name

  vpc_id  = module.mpi-cluster-vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule = "all-tcp"
      source_security_group_id = module.mpi-cluster-security-group.this_security_group_id
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      source_security_group_id = module.mpi-cluster-public-alb-security-group.this_security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.mpi-cluster-vpc.vpc_cidr_block
    },
    {
      from_port   = 2222
      to_port     = 2222
      protocol    = "tcp"
      cidr_blocks = module.mpi-cluster-vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = var.tags
}

module "mpi-cluster-role" {
  source = "../terraform-aws-role"
  role_name = var.name
  account_id = var.account_id
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
  policy_path = "${path.module}/data/policies/mpi_cluster_ec2_iam_policy.json"
  tags = var.tags
}

module "mpi-cluster-efs" {

  source = "../terraform-aws-efs"

  subnet_count = length(module.mpi-cluster-vpc.private_subnets)
  subnets = module.mpi-cluster-vpc.private_subnets
  security_groups = [module.mpi-cluster-security-group.this_security_group_id]

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-efs"
    },
  )
}

resource "tls_private_key" "mpi-cluster-openssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_lb" "mpi-cluster-nlb" {

  name               = "${var.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.mpi-cluster-vpc.private_subnets

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-nlb"
    },
  )
}

resource "aws_lb_listener" "mpi-cluster-headnode-nlb-listener" {

  load_balancer_arn = aws_lb.mpi-cluster-nlb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.mpi-cluster-headnode-target-group.arn}"
  }
}

resource "aws_lb_listener" "mpi-cluster-compute-nlb-listener" {

  load_balancer_arn = aws_lb.mpi-cluster-nlb.arn
  port              = "2222"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.mpi-cluster-compute-target-group.arn}"
  }
}

resource "aws_lb_target_group" "mpi-cluster-headnode-target-group" {

  name     = "${var.name}-headnode"
  port     = 22
  protocol = "TCP"
  vpc_id   = module.mpi-cluster-vpc.vpc_id
  health_check {
    protocol = "TCP"
    interval = 10
    port = 22
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "mpi-cluster-compute-target-group" {

  name     = "${var.name}-compute"
  port     = 2222
  protocol = "TCP"
  vpc_id   = module.mpi-cluster-vpc.vpc_id
  health_check {
    protocol = "TCP"
    interval = 10
    port = 2222
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

module "mpi-cluster-public-alb-security-group" {

  source = "../terraform-aws-security-group"

  name = "${var.name}-public"
  vpc_id  = module.mpi-cluster-vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = var.tags
}


module "mpi-cluster-public-alb" {
  source              = "../terraform-aws-alb"
  load_balancer_name  = "${var.name}-public"
  load_balancer_is_internal = false
  idle_timeout        = 300
  security_groups     = [module.mpi-cluster-public-alb-security-group.this_security_group_id]

  vpc_id              = module.mpi-cluster-vpc.vpc_id
  subnets             = module.mpi-cluster-vpc.public_subnets

  https_listeners_count = 1
  https_listeners = [
    {
      "port"               = 443
      "certificate_arn"    = "arn:aws:acm:ap-southeast-1:${var.account_id}:certificate/9f31be4f-ee60-41bc-8aa8-3de34586227d"
    },
  ]

  target_groups_count = 1
  target_groups = [
    {
      "name"                 = "${var.name}-public"
      "backend_protocol"     = "HTTP"
      "backend_port"         = 80
      "slow_start"           = 60
      "health_check_matcher" = "200-499"
      "deregistration_delay" = 10
      "stickiness_enabled"   = false
      "health_check_path"      = "/"
    },
  ]

  logging_enabled        = false

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-public"
    },
  )
}


data "template_file" "mpi-cluster-headnode-launch-configuration" {

  template = "${file("${path.module}/data/launch-configs/aws_launch_config_mpi_cluster_headnode.tpl")}"

  vars = {
    AWS_EFS_DNS_NAME = module.mpi-cluster-efs.dns_name
    AWS_MPI_COMPUTE_HOST = "*"
    AWS_MPI_CLUSTER_PRIVATE_KEY = tls_private_key.mpi-cluster-openssh-key.private_key_pem
    AWS_MPI_CLUSTER_PUBLIC_KEY = tls_private_key.mpi-cluster-openssh-key.public_key_openssh
    AWS_MPI_COMPUTE_TARGET_GROUP_ARN = aws_lb_target_group.mpi-cluster-compute-target-group.arn
  }
}

module "mpi-cluster-headnode-asg" {

  source = "../terraform-aws-autoscaling"
  name = "${var.name}-headnode"

  key_name = var.key_name
  lc_name = "${var.name}-headnode"
  image_id = var.archanan_headnode_ami
  instance_type = var.archanan_headnode_instance_type
  security_groups = [module.mpi-cluster-security-group.this_security_group_id]

  iam_instance_profile = module.mpi-cluster-role.iam_instance_profile_name

  root_block_device = [
    {
      volume_size = var.archanan_headnode_root_volume_size
      volume_type = var.archanan_headnode_root_volume_type
    },
  ]

  asg_name                  = "${var.name}-headnode"
  vpc_zone_identifier       = module.mpi-cluster-vpc.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 240
  default_cooldown          = 10
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  target_group_arns         = ["${aws_lb_target_group.mpi-cluster-headnode-target-group.arn}"]

  #load_balancers           = [module.jenkins-alb.load_balancer_id]

  user_data                 = "${data.template_file.mpi-cluster-headnode-launch-configuration.rendered}"

  tags = local.tags_asg_format

}

data "template_file" "mpi-cluster-compute-launch-configuration" {

  template = "${file("${path.module}/data/launch-configs/aws_launch_config_mpi_cluster_compute.tpl")}"

  vars = {
    AWS_EFS_DNS_NAME = module.mpi-cluster-efs.dns_name
    AWS_MPI_COMPUTE_DOCKER_REPO = var.archanan_compute_docker_repo
    AWS_MPI_COMPUTE_DOCKER_TAG = var.archanan_compute_docker_tag
  }

}

module "mpi-cluster-compute-asg" {

  source = "../terraform-aws-autoscaling"
  name = "${var.name}-compute"

  key_name = var.key_name
  lc_name = "${var.name}-compute"
  image_id = var.archanan_compute_ami
  instance_type = var.archanan_compute_instance_type
  security_groups = [module.mpi-cluster-security-group.this_security_group_id]

  iam_instance_profile = module.mpi-cluster-role.iam_instance_profile_name

  root_block_device = [
    {
      volume_size = var.archanan_compute_root_volume_size
      volume_type = var.archanan_compute_root_volume_type
    },
  ]

  asg_name                  = "${var.name}-compute"
  vpc_zone_identifier       = module.mpi-cluster-vpc.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 240
  default_cooldown          = 10
  min_size                  = 1
  max_size                  = var.archanan_compute_number
  desired_capacity          = var.archanan_compute_number
  wait_for_capacity_timeout = 0

  target_group_arns         = ["${aws_lb_target_group.mpi-cluster-compute-target-group.arn}"]
  user_data                 = "${data.template_file.mpi-cluster-compute-launch-configuration.rendered}"

  tags = local.tags_asg_format
}

data "template_file" "mpi-cluster-api-gateway-launch-configuration" {
  template = "${file("${path.module}/data/launch-configs/aws_launch_config_mpi_cluster_api_gateway.tpl")}"

  vars = {
    AWS_API_GATEWAY_DOCKER_REPO = var.archanan_api_gateway_docker_repo
    AWS_API_GATEWAY_DOCKER_TAG = var.archanan_api_gateway_docker_tag
  }
}

module "mpi-cluster-api-gateway-asg" {

  source = "../terraform-aws-autoscaling"
  name = "${var.name}-api-gateway"

  key_name = var.key_name
  lc_name = "${var.name}-api-gateway"
  image_id = var.archanan_api_gateway_ami
  instance_type = var.archanan_api_gateway_instance_type
  security_groups = [module.mpi-cluster-security-group.this_security_group_id]

  iam_instance_profile = module.mpi-cluster-role.iam_instance_profile_name

  root_block_device = [
    {
      volume_size = var.archanan_api_gateway_root_volume_size
      volume_type = var.archanan_api_gateway_root_volume_type
    },
  ]

  asg_name                  = "${var.name}-api-gateway"
  vpc_zone_identifier       = module.mpi-cluster-vpc.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 240
  default_cooldown          = 10
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  target_group_arns         = module.mpi-cluster-public-alb.target_group_arns
  user_data                 = "${data.template_file.mpi-cluster-api-gateway-launch-configuration.rendered}"

  tags = local.tags_asg_format
}
