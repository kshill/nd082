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

variable "contact" {}

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


locals {
  nsgrules = {
    
    vnet_to_vnet_access = {
      name                        = "allow_vnet_to_vnet_access"
      priority                    = 102
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "VirtualNetwork"
      destination_address_prefix  = "VirtualNetwork"

    }

    internet_to_lb_access = {
      name                        = "allow_vnet_all"
      priority                    = 103
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "TCP"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }

    deny_internet_to_vnet_access = {
      name                        = "deny_internet_to_vnet"
      priority                    = 120
      direction                   = "Inbound"
      access                      = "Deny"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "Internet"
      destination_address_prefix  = "VirtualNetwork"
    }
  }
}