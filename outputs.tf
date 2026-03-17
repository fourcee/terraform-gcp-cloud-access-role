output "custom_role_ids" {
  description = "Map of custom role IDs to their full resource names"
  value = merge(
    { for k, v in google_project_iam_custom_role.custom_role : k => v.id },
    { for k, v in google_organization_iam_custom_role.custom_role : k => v.id }
  )
}

output "custom_role_names" {
  description = "Map of custom role IDs to their names"
  value = merge(
    { for k, v in google_project_iam_custom_role.custom_role : k => v.name },
    { for k, v in google_organization_iam_custom_role.custom_role : k => v.name }
  )
}

output "assigned_roles" {
  description = "List of all roles that have been assigned"
  value = distinct(concat(
    [for binding in local.project_predefined_bindings : binding.role],
    [for binding in local.project_custom_bindings : binding.role],
    [for binding in local.folder_predefined_bindings : binding.role],
    [for binding in local.folder_custom_bindings : binding.role]
  ))
}

output "assigned_principals" {
  description = "List of all principals that have been assigned roles"
  value       = var.group_principals
}

output "pam_entitlement_name" {
  description = "The created PAM entitlement Name when jit_enabled is true"
  value       = try(google_privileged_access_manager_entitlement.jit[0].name, null)
}
