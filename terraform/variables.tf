variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "adminuser"
} 