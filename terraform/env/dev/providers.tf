variable "role_arn" {
  description = "Export your TF_VAR_role_arn to run terraform"
  type        = string
  default     = "xxxxxxxxxxxx"
}

variable "external_id" {
  description = "Export your TF_VAR_external_id to run terraform"
  type        = string
  default     = "xxxxxxxxxxxx"
}

provider "aws" {
  version = "2.17.0"
  region = "ap-southeast-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/${var.role_arn}"
    external_id = "${var.external_id}"
  }
}

terraform {
  required_version = "=0.12.8"
  backend "s3" {
    bucket         = "terraform-state.ascendaloyalty.com"
    key            = "dev/demo/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = "true"
  }
}
