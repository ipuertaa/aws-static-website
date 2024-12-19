# variables for tagging moduule

variable "region" {
  description = "The region where the resources will be created"
  type        = string
  default     = "us-east-1"
}

# variable "required_tags" {
#   description = "Required Tags for AWS Resources"
#   type        = map(string)
# }

# variable "owner" {
#   description = "Owner of the resources"
#   type        = string
# }

# variable "application" {
#   description = "Application name"
#   type        = string
# }

# variable "managedBy" {
#   description = "Managed by"
#   type        = string
#   default = "terraform"
# }

# variable "environment" {
#   description = "Environment"
#   type        = string
# }

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "managedBy" {
  description = "Managed by"
  type        = string
  default = "terraform"
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "ttl" {
  description = "Time to live for the resources"
  type        = number
  default = null
  
}

variable "expiration" {
  description = "Expiration date for the resources"
  type = string
  default = null
}


variable "optional_tags" {
  description = "Required Tags for AWS Resources"
  type        = map(string)
  default = {}
}