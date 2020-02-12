data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  load_config_file       = false

  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = "~>1.10.0"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


module "eks" {
  source          = "../../modules/terraform-aws-eks"
  cluster_name    = local.eks.name
  cluster_version = local.eks.cluster_version
  subnets         = module.eks-vpc.private_subnets

  enable_irsa = true

  tags = local.tags

  vpc_id = module.eks-vpc.vpc_id

  node_groups_defaults = {
    ami_type  = local.eks.node_groups_defaults.ami_type
    disk_size = local.eks.node_groups_defaults.disk_size
  }

  write_kubeconfig = false
  node_groups = local.eks.node_groups
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.6.0"
  create_role                   = true
  role_name                     = "cluster-autoscaler"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler-aws-cluster-autoscaler"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

module "tiller" {
  source   = "../../modules/terraform-k8s-tiller"
  tiller_version = "v2.16.0"
}

resource "kubernetes_secret" "flux-ssh" {
  metadata {
    name = "flux-ssh"
    namespace = "kube-system"
  }

  data = {
    identity = var.flux_ssh_key
  }

  depends_on = [ "module.tiller" ]
}

resource "helm_release" "flux" {
  name       = "flux"
  namespace  = "kube-system"
  repository = "https://charts.fluxcd.io"
  chart      = "flux"
  version    = "1.2.0"
  depends_on = [ "kubernetes_secret.flux-ssh" ]
  values = [
    "${file("${path.root}/data/helm/flux.value.yaml")}"
  ]
}

resource "helm_release" "helm-operator" {
  name       = "helm-operator"
  namespace  = "kube-system"
  repository = "https://charts.fluxcd.io"
  chart      = "helm-operator"
  version    = "0.6.0"
  depends_on = [ "helm_release.flux" ]
  values = [
    "${file("${path.root}/data/helm/helm_operator.value.yaml")}"
  ]
}

data "template_file" "cluster_autoscaler_helm_value" {
  template = "${file("${path.module}/data/helm/cluster_autoscaler.value.yaml.tpl")}"
  vars = {
    AWS_EKS_CLUSTER_NAME = local.eks.name
    AWS_EKS_CLUSTER_REGION = "ap-southeast-1"
    AWS_ACCOUNT_ID = local.account_id
  }
}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "cluster-autoscaler"
  version    = "6.4.0"
  depends_on = [ "helm_release.flux" ]
  values = [
    "${data.template_file.cluster_autoscaler_helm_value.rendered}"
  ]
}
