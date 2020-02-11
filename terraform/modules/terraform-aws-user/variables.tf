variable "username" {
  type        = "string"
  description = "Name of user to create"
}

variable "gpg_key" {
  type        = "string"
  description = "base64 encoded GPG key. See https://www.terraform.io/docs/providers/aws/r/iam_user_login_profile.html for more info"
}

variable "account_id" {
  type        = "string"
  description = "Amazon account id"
}
