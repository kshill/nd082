########### Azure Provider ###########
provider "azurerm" {
  subscription_id = var.subscriptionid
  client_id = var.clientid
  client_secret = var.clientsecret
  tenant_id = var.tenantid
  environment = "public"
  features {}
}

########### Data Queries ###########
data "azurerm_resource_group" "ubuntu_image_rg" {
  name = var.packerRG
}

data "azurerm_image" "ubuntu_image_packer" {
  name                = var.packerImageName
  resource_group_name = data.azurerm_resource_group.ubuntu_image_rg.name
}

########### Azure Policies ###########
resource "azurerm_policy_definition" "taggingPolicy" {
  name         = "tagging-policy"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "tagging-policy"

  metadata = <<METADATA
    {
    "category": "Tags"
    }

METADATA


  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf":  [
            {
                "field": "[concat('tags[', parameters('tagName'), ']')]",
                "exists": "false"
            }
        ]
    },
    "then": {
      "effect": "Deny"
    }
  }
POLICY_RULE


  parameters = <<PARAMETERS
    {
    "tagName": {
      "type": "String",
      "metadata": {
        "displayName": "Name Of Tag",
        "description": "Tag Name Must Be Specified"
      }
    }
  }
PARAMETERS

}

resource "azurerm_policy_assignment" "auditTaggingInSubscription" {
    name = "tagging-policy-assignment"
    scope = "${var.cust_scope}${var.subscriptionid}"
    policy_definition_id = azurerm_policy_definition.taggingPolicy.id
    description = "Denies the creation of resources that do not have a tag."
    display_name = "Deny Resource Creation That Do Not Have Tags"

    metadata = <<METADATA
    {
    "category": "Tags"
    }
METADATA

  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Environment"
  }
}
PARAMETERS
}

########### Resource Group ###########
resource "azurerm_resource_group" "main_rg" {
  name     = "${var.project}-resources"
  location = var.location

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}


########### Virtual Network ###########

resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.project}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main_rg.name

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}

resource "azurerm_subnet" "internal_subnet" {
  name                 = "${var.project}-internal-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.project}-loadbalancer-inbound-IP"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}

resource "azurerm_public_ip" "outbound_public_ip" {
  name                = "${var.project}-loadbalancer-outbound_IP"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}

 resource "azurerm_network_security_group" "udacity_webserver_ingress_ng" {
  name                = "${var.project}-webserver-ng"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_rg.name

  security_rule {
    name                       = "allow_http_from_lb_to_webservers"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_port_range     = "80"
    destination_application_security_group_ids = [azurerm_application_security_group.udacity_webserver_asg.id]
  }

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}

resource "azurerm_network_security_rule" "nsg_rules" {
  for_each = local.nsgrules
  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.main_rg.name
  network_security_group_name = azurerm_network_security_group.udacity_webserver_ingress_ng.name
}

resource "azurerm_application_security_group" "udacity_webserver_asg" {
  name                = "${var.project}-webserver-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_rg.name

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
} 

########### Loadbalancer ###########

resource "azurerm_lb" "udacity_lb" {
  name                = "${var.project}-load-balancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_rg.name
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "Inbound"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  frontend_ip_configuration {
    name                 = "Outbound"
    public_ip_address_id = azurerm_public_ip.outbound_public_ip.id
  }

  depends_on = [ 
    azurerm_public_ip.public_ip
   ]

  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )

}

resource "azurerm_lb_backend_address_pool" "udacity_lb_bap" {
  #resource_group_name = azurerm_resource_group.main_rg.name
  loadbalancer_id     = azurerm_lb.udacity_lb.id
  name                = "${var.project}-backendaddresspool_inbound"
}

resource "azurerm_lb_backend_address_pool" "udacity_lb_bap_outbound" {
  #resource_group_name = azurerm_resource_group.main_rg.name
  loadbalancer_id     = azurerm_lb.udacity_lb.id
  name                = "${var.project}-backendaddresspool_outbound"
}

resource "azurerm_lb_probe" "udacity_lb_probe" {
  resource_group_name = azurerm_resource_group.main_rg.name
  loadbalancer_id     = azurerm_lb.udacity_lb.id
  name                = "${var.project}-http-inbound-probe"
  port                = 80
}

resource "azurerm_lb_rule" "udacity_lb_rule" {
  resource_group_name            = azurerm_resource_group.main_rg.name
  loadbalancer_id                = azurerm_lb.udacity_lb.id
  name                           = "${var.project}-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  enable_tcp_reset               = true
  frontend_ip_configuration_name = "Inbound"
  probe_id = azurerm_lb_probe.udacity_lb_probe.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.udacity_lb_bap.id
}


resource "azurerm_lb_outbound_rule" "udacity_lb_outbound_rule" {
  resource_group_name            = azurerm_resource_group.main_rg.name
  loadbalancer_id                = azurerm_lb.udacity_lb.id
  name                           = "${var.project}-lb-outbound_rule"
  protocol                       = "Tcp"
  
  backend_address_pool_id = azurerm_lb_backend_address_pool.udacity_lb_bap_outbound.id

  frontend_ip_configuration {
    name = "Outbound"
    
  }
  
}

########### VM Scaleset ###########
resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                            = "${var.project}-vm"
  resource_group_name             = azurerm_resource_group.main_rg.name
  location                        = var.location
  instances                       = var.instance_count
  sku                             = "Standard_D2s_v3"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false


  source_image_id = data.azurerm_image.ubuntu_image_packer.id
  

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name = "${var.project}-webserver-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.udacity_webserver_ingress_ng.id


    ip_configuration {
      name                                   = "${var.project}-webserver-ipconfiguration"
      subnet_id                              = azurerm_subnet.internal_subnet.id
      application_security_group_ids = [azurerm_application_security_group.udacity_webserver_asg.id]
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.udacity_lb_bap.id,
        azurerm_lb_backend_address_pool.udacity_lb_bap_outbound.id
        ]
      primary = true
    }
  }


  tags = merge (
    local.common_tags,
    map(
      "Contact", var.contact
    )
  )
}

