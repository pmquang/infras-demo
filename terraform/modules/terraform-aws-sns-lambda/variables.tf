variable "protocol" {
  description = "Protocol of subscription"
  type        = string
}

variable "runtime" {
  type        = string
}

variable "source_file" {
  type        = string
}

variable "output_path" {
  type        = string
}

variable "tags" {
  type        = map
}

variable "lambda_name" {
  type        = string
}

variable "environment_vars" {
  type        = map
  default     = {}
}
