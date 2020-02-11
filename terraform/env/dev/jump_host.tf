// This EC2 instance is used for access internal VPC

module "jumphost-security-group" {

  source = "../../modules/terraform-aws-security-group"

  name = "${local.name}-jumphost-sg"
  vpc_id  = module.internal-vpc.vpc_id

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


resource "aws_instance" "jumphost" {
  ami           = local.image_id
  instance_type = "t2.micro"

  key_name      = local.name
  subnet_id     = module.internal-vpc.public_subnets[0]
  vpc_security_group_ids = [module.jumphost-security-group.this_security_group_id]
  associate_public_ip_address = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-jumphost"
    },
  )
}
