data "external" "account_id" {
  program = ["bash", "${path.module}/data/scripts/get_account_id.sh"]
}

data "aws_ami" "amazon-ami" {
  most_recent = true
  filter {
      name   = "name"
      values = ["amzn2-ami-hvm-2*"]
    }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  owners = ["amazon"]
}


resource "aws_key_pair" "ssh-key" {
  key_name   = local.name
  public_key = "${file("${path.root}/data/credentials/ssh_key.pub")}"
}

locals {

  account_id = "${data.external.account_id.result.account_id}"

  env     = "dev"
  project = "demo"

  name     = "${local.env}-${local.project}"
  image_id = "${data.aws_ami.amazon-ami.id}"

  vpc = {
    eks = {
      name            = "${local.name}-eks"
      cidr            = "10.0.0.0/16"
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    }

    internal = {
      name            = "${local.name}-internal"
      cidr            = "10.1.0.0/16"
      private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
      public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
    }
  }

  jenkins = {
    name                      = "${local.name}-jenkins"
    image_id                  = local.image_id
    docker_repo               = "${local.account_id}.dkr.ecr.ap-southeast-1.amazonaws.com/internal/jenkins"
    docker_tag                = "2.190.1"
    instance_type             = "t2.xlarge"
    root_volume_size          = "50"
    root_volume_type          = "gp2"
    health_check_grace_period = 240
    default_cooldown          = 10
    min_size                  = 0
    max_size                  = 1
    desired_capacity          = 1
    awslog_region             = "ap-southeast-1"
    awslog_group              = "${local.name}"
    awslog_stream             = "jenkins"
  }

  eks = {
    name                      = "${local.name}-eks"
    cluster_version           = "1.14"
    node_groups_defaults      = {
      ami_type  = "AL2_x86_64"
      disk_size = 50
    }

    node_groups = {
      nodegroup01 = {
        desired_capacity = 5
        max_capacity     = 20
        min_capacity     = 1

        instance_type = "c5.2xlarge"
        k8s_labels = {
          Environment = local.env
        }
        additional_tags = {
          ExtraTag = "${local.name}-eks-nodegroup01"
        }
      }
    }
  }

  tags = {
    Owner       = "quang.pham"
    Environment = local.env
    Project     = local.project
    Terraform   = "true"
  }
}
