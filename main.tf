locals {
  # Determine if we're working at project or folder level
  is_project_level = var.project_id != null
  is_folder_level  = var.folder_id != null

  # Create a list of all roles (predefined + custom) for assignment
  all_predefined_roles     = var.predefined_roles
  all_custom_roles_project = [for role in var.custom_roles : "projects/${var.project_id}/roles/${role.role_id}" if local.is_project_level]
  all_custom_roles_org     = [for role in var.custom_roles : "organizations/${var.organization_id}/roles/${role.role_id}" if local.is_folder_level]

  # Create combinations of roles and principals for IAM bindings
  project_predefined_bindings = local.is_project_level ? flatten([
    for role in local.all_predefined_roles : [
      for principal in var.group_principals : {
        role      = role
        principal = principal
      }
    ]
  ]) : []

  project_custom_bindings = local.is_project_level ? flatten([
    for role in local.all_custom_roles_project : [
      for principal in var.group_principals : {
        role      = role
        principal = principal
      }
    ]
  ]) : []

  folder_predefined_bindings = local.is_folder_level ? flatten([
    for role in local.all_predefined_roles : [
      for principal in var.group_principals : {
        role      = role
        principal = principal
      }
    ]
  ]) : []

  folder_custom_bindings = local.is_folder_level ? flatten([
    for role in local.all_custom_roles_org : [
      for principal in var.group_principals : {
        role      = role
        principal = principal
      }
    ]
  ]) : []
}

# Create custom roles at project level
resource "google_project_iam_custom_role" "custom_role" {
  for_each = local.is_project_level ? { for role in var.custom_roles : role.role_id => role } : {}

  project     = var.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Create custom roles at organization level (for folder-level assignments)
resource "google_organization_iam_custom_role" "custom_role" {
  for_each = local.is_folder_level ? { for role in var.custom_roles : role.role_id => role } : {}

  org_id      = var.organization_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Assign predefined roles at project level
resource "google_project_iam_member" "predefined_role" {
  for_each = local.is_project_level ? { for idx, binding in local.project_predefined_bindings : "${binding.role}-${binding.principal}" => binding } : {}

  project = var.project_id
  role    = each.value.role
  member  = each.value.principal
}

# Assign custom roles at project level
resource "google_project_iam_member" "custom_role" {
  for_each = local.is_project_level ? { for idx, binding in local.project_custom_bindings : "${binding.role}-${binding.principal}" => binding } : {}

  project = var.project_id
  role    = each.value.role
  member  = each.value.principal

  depends_on = [google_project_iam_custom_role.custom_role]
}

# Assign predefined roles at folder level
resource "google_folder_iam_member" "predefined_role" {
  for_each = local.is_folder_level ? { for idx, binding in local.folder_predefined_bindings : "${binding.role}-${binding.principal}" => binding } : {}

  folder = var.folder_id
  role   = each.value.role
  member = each.value.principal
}

# Assign custom roles at folder level
resource "google_folder_iam_member" "custom_role" {
  for_each = local.is_folder_level ? { for idx, binding in local.folder_custom_bindings : "${binding.role}-${binding.principal}" => binding } : {}

  folder = var.folder_id
  role   = each.value.role
  member = each.value.principal

  depends_on = [google_organization_iam_custom_role.custom_role]
}
