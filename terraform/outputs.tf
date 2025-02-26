output "server_private_ip" {
  description = "Private IP address of the server"
  value       = azurerm_network_interface.nic_server.private_ip_address
}