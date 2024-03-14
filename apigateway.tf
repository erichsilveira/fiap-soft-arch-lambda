resource "aws_cognito_user_pool" "food_service_pool" {
  name = "customer_pool"
}

resource "aws_cognito_user_pool_client" "food_service_client" {
  name                                 = "client"
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = false
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin", "email", "openid", "profile"]
  allowed_oauth_flows                  = ["implicit", "code"]
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  supported_identity_providers         = ["COGNITO"]
  user_pool_id                         = aws_cognito_user_pool.food_service_pool.id

  callback_urls = ["https://example.com"]
  logout_urls   = ["https://example.com"]
}

resource "aws_api_gateway_rest_api" "food_service_api" {
  name = "food_service_api"
}

resource "aws_api_gateway_authorizer" "food_service_authorizer" {
  name          = "food_service_authorizer"
  rest_api_id   = aws_api_gateway_rest_api.food_service_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.food_service_pool.arn]
}

resource "aws_api_gateway_resource" "food_service_api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.food_service_api.id
  parent_id   = aws_api_gateway_rest_api.food_service_api.root_resource_id
  path_part   = var.api_path
}

resource "aws_api_gateway_method" "food_service_method" {
  rest_api_id   = aws_api_gateway_rest_api.food_service_api.id
  resource_id   = aws_api_gateway_resource.food_service_api_gateway.id
  http_method   = var.food_service_http_method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.food_service_authorizer.id
}

resource "aws_api_gateway_integration" "food_service_integration" {
  rest_api_id             = aws_api_gateway_rest_api.food_service_api.id
  resource_id             = aws_api_gateway_resource.food_service_api_gateway.id
  http_method             = aws_api_gateway_method.food_service_method.http_method
  integration_http_method = aws_api_gateway_method.food_service_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${aws_lambda_function.customer_auth_function.function_name}/invocations"
  credentials             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_apigateway_iam_role.name}"
}

resource "aws_api_gateway_method_response" "food_service_method_response" {
  rest_api_id = aws_api_gateway_rest_api.food_service_api.id
  resource_id = aws_api_gateway_resource.food_service_api_gateway.id
  http_method = aws_api_gateway_method.food_service_method.http_method

  response_models = {
    "application/json" = "Empty"
  }

  status_code = "200"
}

resource "aws_api_gateway_integration_response" "food_service_integration_response" {
  depends_on  = ["aws_api_gateway_integration.food_service_integration"]
  rest_api_id = aws_api_gateway_rest_api.food_service_api.id
  resource_id = aws_api_gateway_resource.food_service_api_gateway.id
  http_method = aws_api_gateway_method.food_service_method.http_method
  status_code = aws_api_gateway_method_response.food_service_method_response.status_code
}

resource "aws_api_gateway_deployment" "food_service_deploy" {
  depends_on  = ["aws_api_gateway_integration.food_service_integration"]
  stage_name  = var.api_env_stage_name
  rest_api_id = aws_api_gateway_rest_api.food_service_api.id
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.food_service_pool.id
  username     = "fooduser"
  password     = "Test@123"
}