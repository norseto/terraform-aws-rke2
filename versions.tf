terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = ">= 4.40"
    random = {
      source  = "hashicorp/random"
      version = ">= 2.3.0"
    }
  }
}
