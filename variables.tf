variable "region" {
  default = "us-east-1"
}

variable "lambda_payload_filename" {
  default = "./target/techchallenge-0.0.1-SNAPSHOT.jar"
}

variable "lambda_function_handler" {
  default = "com.fiap.techchallenge.handler.LambdaHandler::handleRequest"
}

variable "lambda_runtime" {
  default = "java11"
}

variable "api_path" {
  default = "auth"
}

variable "food_service_http_method" {
  default = "POST"
}

variable "api_env_stage_name" {
  default = "dev"
}