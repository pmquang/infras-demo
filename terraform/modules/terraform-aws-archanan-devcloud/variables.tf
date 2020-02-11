locals {
  tags_asg_format = null_resource.tags_as_list_of_maps.*.triggers
}

resource "null_resource" "tags_as_list_of_maps" {
  count = length(keys(var.tags))

  triggers = {
    "key"                 = keys(var.tags)[count.index]
    "value"               = values(var.tags)[count.index]
    "propagate_at_launch" = "true"
  }
}

variable "name" {
  type = string
  default = "archanan-mpi"
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_azs" {

}

variable "tags" {
  type = map
  default = {}
}

variable "account_id" {
  type = string
}

variable "archanan_headnode_ami" {
  type = string
  default = "ami-048a01c78f7bae4aa"
}

variable "archanan_headnode_instance_type" {
  type = string
  default = "t2.micro"
}

variable "archanan_headnode_root_volume_size" {
  type = string
  default = "50"
}

variable "archanan_headnode_root_volume_type" {
  type = string
  default = "gp2"
}

variable "key_name" {
  type = string
  default = "dev-integration"
}

variable "archanan_compute_docker_repo" {
  type = string
}

variable "archanan_compute_docker_tag" {
  type = string
}

variable "archanan_compute_ami" {
  type = string
  default = "ami-048a01c78f7bae4aa"
}

variable "archanan_compute_instance_type" {
  type = string
  default = "t2.micro"
}

variable "archanan_compute_number" {
  type = number
  default = 4
}

variable "archanan_compute_root_volume_size" {
  type = string
  default = "50"
}

variable "archanan_compute_root_volume_type" {
  type = string
  default = "gp2"
}


variable "archanan_api_gateway_docker_repo" {
  type = string
}

variable "archanan_api_gateway_docker_tag" {
  type = string
}

variable "archanan_api_gateway_ami" {
  type = string
  default = "ami-048a01c78f7bae4aa"
}

variable "archanan_api_gateway_instance_type" {
  type = string
  default = "t2.micro"
}

variable "archanan_api_gateway_root_volume_size" {
  type = string
  default = "50"
}

variable "archanan_api_gateway_root_volume_type" {
  type = string
  default = "gp2"
}



/*

variable "archanan_headnode_docker_repo" {
  type = string
}

variable "archanan_headnode_docker_tag" {
  type = string
}

variable "archanan_ui_ami" {
  type = string
  default = "ami-048a01c78f7bae4aa"
}

variable "archanan_ui_docker_repo" {
  type = string
}

variable "archanan_ui_docker_tag" {
  type = string
}

variable "archanan_ui_instance_type" {
  type = string
  default = "t2.micro"
}

variable "archanan_backend_services_docker_repo" {
  type = string
}

variable "archanan_backend_services_docker_tag" {
  type = string
}

variable "archanan_backend_services_instance_type" {
  type = string
  default = "t2.micro"
}

*/
