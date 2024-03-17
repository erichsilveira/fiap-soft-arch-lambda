terraform {
  backend "remote" {
    organization = "erichsilveira-org"
    workspaces {
      name = "postech-fiap-lambda"
    }
  }
}