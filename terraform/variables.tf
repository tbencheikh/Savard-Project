variable "admin_password" {
  description = "Mot de passe administrateur pour les machines virtuelles"
  type        = string
  sensitive   = true
  default = ""
}
variable "subscription_id" {
  description = "ID de la souscription Azure"
  type        = string
}

variable "resource_group_name" {
  default = "savard-rg"
}
variable "location" {
  default = "eastus"
}
variable "vnet_name" {
  default = "savard-vnet"
}
variable "subnet_name" {
  default = "savard-subnet"
}
