variable "name" {
  type = string
  default = "cognito-default-name"
}

locals {
  invite_message_template = {
    email_message = "Your username is {username} and temporary password is {####}."
    email_subject = "Your temporary password"
    sms_message   = "Your username is {username} and temporary password is {####}."
  }

  admin_create_user_config = {
    allow_admin_create_user_only = false
    unused_account_validity_days = "7"
  }

  device_configuration = {
    challenge_required_on_new_device = false
    device_only_remembered_on_user_prompt = false
  }

  email_configuration = {
    reply_to_email_address = ""
    source_arn = ""

    ## COGNITO_DEFAULT"|"DEVELOPER
    email_sending_account = "COGNITO_DEFAULT"
  }

  lambda_config = {
    create_auth_challenge = null
    custom_message        = null
    define_auth_challenge = null
    post_authentication   = null
    post_confirmation     = null
    pre_authentication    = null
    pre_sign_up           = null
    pre_token_generation  = null
    user_migration        = null
    verify_auth_challenge_response = null
  }

  verification_message_template = {
    default_email_option  = null ## CONFIRM_WITH_LINK or CONFIRM_WITH_CODE
    email_message         = null ## Conflict with email_verification_message
    email_message_by_link = null ## {##Click Here##}
    email_subject         = null ## Conflict with email_verification_subject
    email_subject_by_link = null
    sms_message           = null ## Conflict with sms_verification_message
  }

  user_pool_add_ons = {
    advanced_security_mode = "OFF"
  }

  password_policy = {
    minimum_length = "8"
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }

  schema = {
    name = null
    attribute_data_type = false
    developer_only_attribute = false
    mutable = false
    required = false
    number_attribute_constraints = {}
    number_attribute_constraints_min_value = "5"
    number_attribute_constraints_max_value = "2048"
    string_attribute_constraints = {}
    string_attribute_constraints_min_length = "5"
    string_attribute_constraints_max_length = "2048"
  }

  user_pool_client = {
    generate_secret = false
    allowed_oauth_scopes = null
    allowed_oauth_flows = null
    callback_urls = null
    logout_urls = null
    default_redirect_uri = null
    explicit_auth_flows = null
    supported_identity_providers = null
    refresh_token_validity = "1"
    write_attributes = []
    read_attributes = []
    allowed_oauth_flows_user_pool_client = false
  }

  user_pool_group = {
    precedence = null
  }

  user_pool_resource_server = {
    scope = {
      scope_description = "Default Scope Description"
    }
  }
}

variable "invite_message_template" {
  type        = map
  default     = {}
}

variable "admin_create_user_config" {
  type        = map
  default     = {}
}

## Email address or phone number section
variable "username_attributes" {
  type        = list
  description = "Possible values in list: phone_number, email"
  default     = null
}

## Username section
variable "alias_attributes" {
  type        = list
  description = "Possible values in list: phone_number, email, preferred_username"
  default     = null
}

variable "auto_verified_attributes" {
  type        = list
  default     = []
}

variable "device_configuration" {
  type    = map
  default = {}
}

variable "email_configuration" {
  type    = map
  default = {}
}

variable "email_verification_subject" {
  type    = string
  default = null
}

variable "email_verification_message" {
  type    = string
  default = null
}

variable "lambda_config" {
  type    = map
  default = {}
}

variable "mfa_configuration" {
  type    = string
  description = "Possible string values: ON, OFF, OPTIONAL"
  default = "OFF"
}

variable "sms_configuration" {
  type    = map
  default = {}
}

variable "sms_verification_message" {
  type    = string
  default = null
}

variable "sms_authentication_message" {
  type    = string
  default = null
}

variable "verification_message_template" {
  type = map
  default = {}
}

variable "user_pool_add_ons" {
  type    = map
  default = {}
}

variable "password_policy" {
  type    = map
  default = {}
}

##[
##  {
##    attribute_data_type = required
##    developer_only_attribute = null
##    mutable = null
##    name = required
##    required = null
##    number_attribute_constraints = {
##      max_value = 1
##      min_value = 10
##   }
##    string_attribute_constraints = {
##      max_length = 1
##      min_length = 10
##    }
##  },
##]

variable "schema" {
  default = []
}

variable "user_pool_client" {
  default = []
}

variable "domain" {
  type    = string
  default = null
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "user_pool_group" {
  type    = list
  default = []
}

variable "user_pool_identity_provider" {
  type    = list
  default = []
}

variable "user_pool_resource_server" {
  type    = list
  default = []
}
