variable "predefined_roles" {
  description = "List of GCP predefined roles to assign to the group principals"
  type        = list(string)
  default     = []
}

variable "custom_roles" {
  description = "List of custom GCP roles to create and assign"
  type = list(object({
    role_id     = string
    title       = string
    description = string
    permissions = list(string)
    stage       = string
  }))
  default = []
}

variable "group_principals" {
  description = "List of GCP group principals (e.g., 'group:example@example.com') to assign roles to"
  type        = list(string)
  default     = []
}

variable "project_id" {
  description = "The GCP project ID to assign permissions at. Must provide either project_id or folder_id."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The GCP folder ID to assign permissions at. Must provide either project_id or folder_id."
  type        = string
  default     = null
}

variable "organization_id" {
  description = "The GCP organization ID. Required when using folder_id to create custom roles at organization level."
  type        = string
  default     = null
}
