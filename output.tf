output "assignment_id" {
    value = azurerm_policy_assignment.auditTaggingInSubscription.id
}

output "loadbalancer_publicIP" {
    value = azurerm_public_ip.public_ip.ip_address
}