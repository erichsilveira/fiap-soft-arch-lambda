resource "aws_lambda_function" "customer_auth_function" {
  function_name = "customer_auth_function"
  filename      = var.lambda_payload_filename

  role             = aws_iam_role.lambda_apigateway_iam_role.arn
  handler          = var.lambda_function_handler
  source_code_hash = filebase64(var.lambda_payload_filename)
  runtime          = var.lambda_runtime
  timeout          = 900
  memory_size      = 1024

  environment {
    variables = {
      POOL_ID   = "${aws_cognito_user_pool.food_service_pool.id}"
      CLIENT_ID = "${aws_cognito_user_pool_client.food_service_client.id}"
    }
  }
}

resource "aws_lambda_permission" "customer_auth_permission" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.customer_auth_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.food_service_api.id}/${aws_api_gateway_deployment.food_service_deploy.stage_name}/${aws_api_gateway_integration.food_service_integration.integration_http_method}${aws_api_gateway_resource.food_service_api_gateway.path}"
}