variable "subnet_count" {
  type        = number
  default     = 1
}

variable "security_groups" {
  description = "A list of security group IDs to assign EFS"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "A list of subnet IDs for mount target"
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = "map"
  default     = {}
}
