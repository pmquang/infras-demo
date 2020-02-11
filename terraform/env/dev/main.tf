data "aws_availability_zones" "available" {
  state = "available"
}

module "eks-vpc" {

  source = "../../modules/terraform-aws-vpc"

  name = "${local.vpc.eks.name}-vpc"
  cidr = local.vpc.eks.cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.vpc.eks.private_subnets
  public_subnets  = local.vpc.eks.public_subnets

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
    local.tags,
    {
      "Name" = local.vpc.eks.name
    },
  )
}

module "internal-vpc" {

  source = "../../modules/terraform-aws-vpc"

  name = "${local.vpc.internal.name}-vpc"
  cidr = local.vpc.internal.cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.vpc.internal.private_subnets
  public_subnets  = local.vpc.internal.public_subnets

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
    local.tags,
    {
      "Name" = local.vpc.internal.name
    },
  )
}
