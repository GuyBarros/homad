terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.6.0"
    }
  }
}

provider "vault" {
  address = var.address
  token   = var.token
}
