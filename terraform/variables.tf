variable "owner-tag" {
  description = "The name of the owner of the resources"
  type        = string
  default     = "isabel"
}

variable "region" {
  description = "The region where the resources will be created"
  type        = string
  default     = "us-east-1"
}


# variable "tags" {
#   description = "Tags to assign to resources"
#   type        = map(string)
#   default = {
#     owner       = "isabel"
#     application = "static-website"
#   }
# }

