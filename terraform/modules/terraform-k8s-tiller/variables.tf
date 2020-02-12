variable "namespace" {
  type = "string"
  default = "kube-system"
}

variable "tiller_version" {
  type    = "string"
  default = "v2.14.0"
}

variable "tiller_image" {
  type    = "string"
  default = "gcr.io/kubernetes-helm/tiller"
}

variable "max_history" {
  type    = "string"
  default = "5"
}

locals {
  tiller_port = 44134
  http_port   = 44135
}
