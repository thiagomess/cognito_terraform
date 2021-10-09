terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

provider "aws" {
  version = "~> 3.60.0"
  region  = "us-east-1"
}



resource "aws_cognito_user_pool" "pool" {
  name = "pool_users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  username_configuration {
    case_sensitive = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    attribute_data_type      = "String"
    name                     = "phone_number"
    required                 = true
    mutable                  = false
    developer_only_attribute = false
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }

  }
  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    mutable                  = false
    developer_only_attribute = false


    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }

  }

  schema {
    attribute_data_type      = "String"
    name                     = "name"
    required                 = true
    mutable                  = false
    developer_only_attribute = false

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }

  }

  password_policy {
    minimum_length                   = "8"
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  email_configuration {
    email_sending_account  = "COGNITO_DEFAULT" #or DEVELOPER
    from_email_address     = "" #MyCompany <no-reply@thiagomess19.de>
    reply_to_email_address = ""
    source_arn             = ""
  }

  lambda_config {
    create_auth_challenge          = ""
    custom_message                 = ""
    define_auth_challenge          = ""
    post_authentication            = ""
    post_confirmation              = ""
    pre_authentication             = ""
    pre_sign_up                    = ""
    pre_token_generation           = ""
    user_migration                 = ""
    verify_auth_challenge_response = ""
  }

  tags = {
    key = "value"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  count = 1
  name  = "name_app"

  user_pool_id        = aws_cognito_user_pool.pool.id
  generate_secret     = true
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]


  access_token_validity  = 20
  refresh_token_validity = 1
  id_token_validity      = 20

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  prevent_user_existence_errors = "LEGACY"
}


resource "aws_secretsmanager_secret" "secret" {
  count = 1
  name  = "secret_cognito"

  tags = {
    key = "value"
  }
}

resource "aws_secretsmanager_secret_version" "sversion" {
  count         = 1
  secret_id     = aws_secretsmanager_secret.secret[count.index].id
  secret_string = <<EOF
   {
    "poolId":${aws_cognito_user_pool.pool.id},
    "appclientId": "${aws_cognito_user_pool_client.client[count.index].id}",
    "appclientSecret": "${aws_cognito_user_pool_client.client[count.index].client_secret}"
   }
EOF



}
