variable "vm_name" {
  description = "Name of the VM"
}

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "location" {
  description = "Azure region"
}

variable "vm_size" {
  description = "Size of the VM"
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
}

variable "admin_password" {
  description = "Admin password for the VM"
}

variable "nic_id" {
  description = "Network interface ID"
}

variable "disk_size_gb" {
  description = "Size of the OS disk in GB"
  default     = 30
}

variable "image_publisher" {
  description = "Publisher of the VM image"
}

variable "image_offer" {
  description = "Offer of the VM image"
}

variable "image_sku" {
  description = "SKU of the VM image"
}