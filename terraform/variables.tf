variable "admin_password" {
  description = "Mot de passe administrateur pour les machines virtuelles"
  type        = string
  sensitive   = true
}
variable "subscription_id" {
  description = "ID de la souscription Azure"
  type        = string
}
