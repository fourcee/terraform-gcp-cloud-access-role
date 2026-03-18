variable "predefined_roles" {
  description = "List of GCP predefined roles with optional IAM conditions to assign to the group principals"
  type = list(object({
    role = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default     = []

  validation {
    condition = alltrue([
      for role in var.predefined_roles :
      trim(role.role) != "" &&
      (
        role.condition == null || (
          trim(role.condition.title) != "" &&
          trim(role.condition.description) != "" &&
          trim(role.condition.expression) != ""
        )
      )
    ])
    error_message = "Each predefined_roles entry must include a non-empty role. If condition is provided, condition.title, condition.description, and condition.expression must be non-empty."
  }
}

variable "custom_roles" {
  description = "List of custom GCP roles to create and assign, with optional IAM conditions for the assignment"
  type = list(object({
    role_id     = string
    title       = string
    description = string
    permissions = list(string)
    stage       = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for role in var.custom_roles :
      trim(role.role_id) != "" &&
      trim(role.title) != "" &&
      trim(role.description) != "" &&
      length(role.permissions) > 0 &&
      trim(role.stage) != "" &&
      (
        role.condition == null || (
          trim(role.condition.title) != "" &&
          trim(role.condition.description) != "" &&
          trim(role.condition.expression) != ""
        )
      )
    ])
    error_message = "Each custom_roles entry must include non-empty role metadata and at least one permission. If condition is provided, condition.title, condition.description, and condition.expression must be non-empty."
  }
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

variable "jit_enabled" {
  description = "Whether to create JIT PAM entitlements instead of regular IAM assignments."
  type        = bool
  default     = false
}

variable "jit_require_justification" {
  description = "Whether PAM activation requests must include justification."
  type        = bool
  default     = false
}

variable "jit_max_activation_duration_seconds" {
  description = "Maximum PAM activation duration, in seconds."
  type        = number
  default     = 3600
}

variable "jit_approval_group_principals" {
  description = "List of group principals that can approve PAM activation requests. If empty, no approval workflow is configured."
  type        = list(string)
  default     = []
}

variable "jit_entitlement_prefix" {
  description = "Prefix to use for the JIT entitlement ID"
  type = string
  default = null
}
