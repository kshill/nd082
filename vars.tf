variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "East US"
}

variable "project" {
  description = "Name of project"
}

variable "clientid" {}

variable "subscriptionid" {}

variable "clientsecret" {}

variable "tenantid" {}

variable "admin_username" {}

variable "admin_password" {}

variable "cust_scope" {
    default = "/subscriptions/"
}

variable "packerRG" {
    default = "packer-rg"
}

variable "instance_count" {
  default = 1
}

variable "packerImageName" {
  default = "UbuntuWebServer_Packer"
}

locals {
  common_tags = {
    Environment = "Production"
    CreatedBy = "Terraform"
    "Project Name" = var.project
  }
}