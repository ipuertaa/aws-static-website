# variable "required_tags" {
#   description = "Required Tags for AWS Resources"
#   type        = map(string)  
# }

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

output "required_tags" {
    description = "Required Tags for AWS Resources"
    # value = {
    #     Owner = var.owner
    #     Application = var.application
    #     Environment = var.environment
    #     ManagedBy = var.managedBy
    # }

    value = merge(var.optional_tags,
    {
        Owner = var.owner
        Application = var.application
        Environment = var.environment
        ManagedBy = var.managedBy
    }
    )
}
