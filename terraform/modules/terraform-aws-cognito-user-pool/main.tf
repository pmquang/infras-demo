resource "aws_iam_policy" "this" {
  count = var.mfa_configuration == "ON" || length(var.sms_configuration) != 0 ? 1 : 0
  name   = "${var.name}-policy"
  policy = "${file("${path.module}/data/policies/cognito_sns_publish_policy.json")}"
}

resource "aws_iam_role" "this" {
  count = var.mfa_configuration == "ON" || length(var.sms_configuration) != 0 ? 1 : 0
  name = "${var.name}-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.sms_configuration.external_id}"
        }
      }
    }
  ]
}
POLICY
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.mfa_configuration == "ON" || length(var.sms_configuration) != 0 ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_cognito_user_pool" "this" {
  name = var.name

  alias_attributes           = var.alias_attributes
  username_attributes        = var.username_attributes
  auto_verified_attributes   = var.auto_verified_attributes
  email_verification_subject = var.email_verification_subject
  email_verification_message = var.email_verification_message
  sms_authentication_message = var.sms_authentication_message
  mfa_configuration          = var.mfa_configuration

  admin_create_user_config {
    allow_admin_create_user_only  = lookup(
                                      var.admin_create_user_config,
                                      "allow_admin_create_user_only",
                                      local.admin_create_user_config.allow_admin_create_user_only
                                    )
    unused_account_validity_days  = lookup(
                                      var.admin_create_user_config,
                                      "unused_account_validity_days",
                                      local.admin_create_user_config.unused_account_validity_days
                                    )

    invite_message_template {
      email_message = lookup(
                        var.invite_message_template,
                        "email_message",
                        local.invite_message_template.email_message
                      )
      email_subject = lookup(
                        var.invite_message_template,
                        "email_subject",
                        local.invite_message_template.email_subject
                      )
      sms_message   = lookup(
                        var.invite_message_template,
                        "sms_message",
                        local.invite_message_template.sms_message
                      )
    }
  }

  device_configuration {
    challenge_required_on_new_device      = lookup(
                                              var.device_configuration,
                                              "challenge_required_on_new_device",
                                              local.device_configuration.challenge_required_on_new_device
                                            )
    device_only_remembered_on_user_prompt = lookup(
                                              var.device_configuration,
                                              "device_only_remembered_on_user_prompt",
                                              local.device_configuration.device_only_remembered_on_user_prompt
                                            )
  }

  email_configuration {
    reply_to_email_address = lookup(
                                var.email_configuration,
                                "reply_to_email_address",
                                local.email_configuration.reply_to_email_address
                              )
    source_arn             = lookup(
                                var.email_configuration,
                                "source_arn",
                                local.email_configuration.source_arn
                              )
    email_sending_account  = lookup(
                                var.email_configuration,
                                "email_sending_account",
                                local.email_configuration.email_sending_account
                              )
  }

  dynamic "lambda_config" {
    for_each = var.lambda_config
    content {
      create_auth_challenge           = lookup(
                                          var.lambda_config,
                                          "create_auth_challenge",
                                          local.lambda_config.create_auth_challenge
                                        )
      custom_message                  = lookup(
                                          var.lambda_config,
                                          "custom_message",
                                          local.lambda_config.custom_message
                                        )
      define_auth_challenge           = lookup(
                                          var.lambda_config,
                                          "define_auth_challenge",
                                          local.lambda_config.define_auth_challenge
                                        )
      post_authentication             = lookup(
                                          var.lambda_config,
                                          "post_authentication",
                                          local.lambda_config.post_authentication
                                        )
      post_confirmation               = lookup(
                                          var.lambda_config,
                                          "post_confirmation",
                                          local.lambda_config.post_confirmation
                                        )
      pre_authentication              = lookup(
                                          var.lambda_config,
                                          "pre_authentication",
                                          local.lambda_config.pre_authentication
                                      )
      pre_sign_up                     = lookup(
                                          var.lambda_config,
                                          "pre_sign_up",
                                          local.lambda_config.pre_sign_up
                                        )
      pre_token_generation            = lookup(
                                          var.lambda_config,
                                          "pre_token_generation",
                                          local.lambda_config.pre_token_generation
                                        )
      user_migration                  = lookup(
                                          var.lambda_config,
                                          "user_migration",
                                          local.lambda_config.user_migration
                                        )
      verify_auth_challenge_response  = lookup(
                                          var.lambda_config,
                                          "verify_auth_challenge_response",
                                          local.lambda_config.verify_auth_challenge_response
                                        )
    }
  }

  dynamic "sms_configuration" {
    for_each = var.sms_configuration
    content {
      external_id = var.sms_configuration.external_id
      sns_caller_arn = aws_iam_role.this[0].arn
    }
  }

  sms_verification_message = var.sms_verification_message

  verification_message_template {
    default_email_option  = lookup(
                              var.verification_message_template,
                              "default_email_option",
                              local.verification_message_template.default_email_option
                            )
    email_message         = lookup(
                              var.verification_message_template,
                              "email_message",
                              local.verification_message_template.email_message
                            )
    email_message_by_link = lookup(
                              var.verification_message_template,
                              "email_message_by_link",
                              local.verification_message_template.email_message_by_link
                            )
    email_subject         = lookup(
                              var.verification_message_template,
                              "email_subject",
                              local.verification_message_template.email_subject
                            )
    email_subject_by_link = lookup(
                              var.verification_message_template,
                              "email_subject_by_link",
                              local.verification_message_template.email_subject_by_link
                            )
    sms_message           = lookup(
                              var.verification_message_template,
                              "sms_message",
                              local.verification_message_template.sms_message
                            )
  }

  password_policy {
    minimum_length    = lookup(
                          var.password_policy,
                          "minimum_length",
                          local.password_policy.minimum_length
                        )
    require_lowercase = lookup(
                          var.password_policy,
                          "require_lowercase",
                          local.password_policy.require_lowercase
                        )
    require_numbers   = lookup(
                          var.password_policy,
                          "require_numbers",
                          local.password_policy.require_numbers
                        )
    require_symbols   = lookup(
                          var.password_policy,
                          "require_symbols",
                          local.password_policy.require_symbols
                        )
    require_uppercase = lookup(
                          var.password_policy,
                          "require_uppercase",
                          local.password_policy.require_uppercase
                        )
  }

  user_pool_add_ons {
    advanced_security_mode = lookup(
                                var.user_pool_add_ons,
                                "advanced_security_mode",
                                local.user_pool_add_ons.advanced_security_mode
                              )
  }

  dynamic "schema" {
    for_each = [ for s in var.schema: {
      attribute_data_type          = lookup(
                                        s,
                                        "attribute_data_type",
                                        local.schema.attribute_data_type
                                      )
      developer_only_attribute     = lookup(
                                        s,
                                        "developer_only_attribute",
                                        null
                                      )
      mutable                      = lookup(
                                        s,
                                        "mutable",
                                        local.schema.mutable
                                      )
      name                         = lookup(
                                        s,
                                        "name",
                                        local.schema.name
                                      )
      required                     = lookup(
                                        s,
                                        "required",
                                        local.schema.required
                                      )
      number_attribute_constraints = lookup(
                                        s,
                                        "number_attribute_constraints",
                                        local.schema.number_attribute_constraints
                                      )
      string_attribute_constraints = lookup(
                                        s,
                                        "string_attribute_constraints",
                                        local.schema.string_attribute_constraints
                                      )
    }]

    content {
      attribute_data_type = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable = schema.value.mutable
      name = schema.value.name
      required = schema.value.required

      dynamic "number_attribute_constraints" {
        for_each = length(schema.value.number_attribute_constraints) != 0 ? [schema.value.number_attribute_constraints] : []
        content {
          min_value = lookup(
                        schema.value.number_attribute_constraints,
                        "min_value",
                        local.schema.number_attribute_constraints_min_value
                      )
          max_value = lookup(
                        schema.value.number_attribute_constraints,
                        "max_value",
                        local.schema.number_attribute_constraints_max_value
                      )
        }
      }

      dynamic "string_attribute_constraints" {
        for_each = length(schema.value.string_attribute_constraints) != 0 ? [schema.value.string_attribute_constraints] : []
        content {
          min_length = lookup(
                          schema.value.string_attribute_constraints,
                          "min_length",
                          local.schema.string_attribute_constraints_min_length
                        )
          max_length = lookup(
                          schema.value.string_attribute_constraints,
                          "max_length",
                          local.schema.string_attribute_constraints_max_length
                        )
        }
      }
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  count = length(var.user_pool_client)

  name = var.user_pool_client[count.index].name
  user_pool_id = "${aws_cognito_user_pool.this.id}"

  generate_secret              = lookup(
                                    var.user_pool_client[count.index],
                                    "generate_secret",
                                    local.user_pool_client.generate_secret
                                  )
  allowed_oauth_flows          = lookup(
                                    var.user_pool_client[count.index],
                                    "allowed_oauth_flows",
                                    local.user_pool_client.allowed_oauth_flows
                                  )
  allowed_oauth_scopes         = lookup(
                                    var.user_pool_client[count.index],
                                    "allowed_oauth_scopes",
                                    local.user_pool_client.allowed_oauth_scopes
                                  )
  callback_urls                = lookup(
                                    var.user_pool_client[count.index],
                                    "callback_urls",
                                    local.user_pool_client.callback_urls
                                  )
  logout_urls                  = lookup(
                                    var.user_pool_client[count.index],
                                    "logout_urls",
                                    local.user_pool_client.logout_urls
                                  )
  default_redirect_uri         = lookup(
                                    var.user_pool_client[count.index],
                                    "default_redirect_uri",
                                    local.user_pool_client.default_redirect_uri
                                  )
  explicit_auth_flows          = lookup(
                                    var.user_pool_client[count.index],
                                    "explicit_auth_flows",
                                    local.user_pool_client.explicit_auth_flows
                                  )
  supported_identity_providers = lookup(
                                    var.user_pool_client[count.index],
                                    "supported_identity_providers",
                                    local.user_pool_client.supported_identity_providers
                                  )
  refresh_token_validity       = lookup(
                                    var.user_pool_client[count.index],
                                    "refresh_token_validity",
                                    local.user_pool_client.refresh_token_validity
                                  )
  write_attributes             = lookup(
                                    var.user_pool_client[count.index],
                                    "write_attributes",
                                    local.user_pool_client.write_attributes
                                  )
  read_attributes              = lookup(
                                    var.user_pool_client[count.index],
                                    "read_attributes",
                                    local.user_pool_client.read_attributes
                                  )

  allowed_oauth_flows_user_pool_client = lookup(
                                            var.user_pool_client[count.index],
                                            "allowed_oauth_flows_user_pool_client",
                                            local.user_pool_client.allowed_oauth_flows_user_pool_client
                                          )
}

resource "aws_cognito_user_pool_domain" "this" {
  count           = var.domain != null || var.certificate_arn != null ? 1 : 0

  user_pool_id    = "${aws_cognito_user_pool.this.id}"

  domain          = var.domain
  certificate_arn = var.certificate_arn
}

resource "aws_iam_role" "group_role" {
  count = length(var.user_pool_group)

  name = "${var.user_pool_group[count.index].name}-role"
  assume_role_policy = var.user_pool_group[count.index].assume_role_policy
}

resource "aws_iam_policy" "group_policy" {
  count = length(var.user_pool_group)

  name = "${var.user_pool_group[count.index].name}-policy"
  policy = var.user_pool_group[count.index].policy
}

resource "aws_iam_role_policy_attachment" "group_policy_attachment" {
  count = length(var.user_pool_group)

  role       = aws_iam_role.group_role[count.index].name
  policy_arn = aws_iam_policy.group_policy[count.index].arn
}


resource "aws_cognito_user_group" "this" {
  count = length(var.user_pool_group)

  name = var.user_pool_group[count.index].name

  user_pool_id = "${aws_cognito_user_pool.this.id}"
  role_arn     = "${aws_iam_role.group_role[count.index].arn}"
  precedence   = lookup(
                    var.user_pool_group[count.index],
                    "precedence",
                    local.user_pool_group.precedence
                  )
}

resource "aws_cognito_identity_provider" "this" {
  count = length(var.user_pool_identity_provider)

  user_pool_id = "${aws_cognito_user_pool.this.id}"

  provider_name = var.user_pool_identity_provider[count.index].provider_name
  provider_type = var.user_pool_identity_provider[count.index].provider_type
  provider_details = var.user_pool_identity_provider[count.index].provider_details
  attribute_mapping = var.user_pool_identity_provider[count.index].attribute_mapping
}

resource "aws_cognito_resource_server" "this" {
  count = length(var.user_pool_resource_server)

  user_pool_id = "${aws_cognito_user_pool.this.id}"

  name = var.user_pool_resource_server[count.index].name
  identifier = var.user_pool_resource_server[count.index].identifier

  dynamic "scope" {
    for_each = [for rs in var.user_pool_resource_server[count.index].scope: {
      scope_name = rs.scope_name
      scope_description = rs.scope_name
    }]
    content {
      scope_name = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}
