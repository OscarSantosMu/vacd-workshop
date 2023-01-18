variable "location" {
  description = ""
  type        = string
}

variable "uniquer" {
  description = ""
  type        = string
  default     = null
}

variable "resources_prefix" {
  description = ""
  type        = string
  default     = null
}

variable "vm_user" {
  description = "Name of the assigned user"
  type        = string
  default     = null
}

variable "vm_user_password" {
  description = "Password of the assigned user"
  type        = string
  default     = null
}