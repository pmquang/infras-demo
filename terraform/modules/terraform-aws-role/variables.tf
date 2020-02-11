variable "role_name" {
  type        = "string"
  description = "Name of the role"
}

variable "username" {
  type        = "string"
  description = "Name of user to be allowed to use the role"
  default     = ""
}

variable "policy_path" {
  type        = "string"
  description = "Path of the policy"
}

variable "account_id" {
  type        = "string"
  description = "Amazon account ID"
  default     = ""
}

variable "custom_assume_role_policy" {
  type        = "string"
  description = "Custom assume role policy"
  default     = ""
}

variable "tags" {
  type        = "map"
  default     = {}
}

variable "iam_instance_profile" {
  type        = "string"
  default     = "false"
}


