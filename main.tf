locals {
  # Determine if we're working at project or folder level
  is_project_level = var.project_id != null
  is_folder_level  = var.folder_id != null

  # Create a list of all roles (predefined + custom) for assignment
  all_predefined_roles = var.predefined_roles
  all_custom_roles_project = [
    for role in var.custom_roles : {
      role      = "projects/${var.project_id}/roles/${role.role_id}"
      condition = try(role.condition, null)
    } if local.is_project_level
  ]
  all_custom_roles_org = [
    for role in var.custom_roles : {
      role      = "organizations/${var.organization_id}/roles/${role.role_id}"
      condition = try(role.condition, null)
    } if local.is_folder_level
  ]

  # Create combinations of roles and principals for IAM bindings
  project_predefined_bindings = local.is_project_level ? flatten([
    for role in local.all_predefined_roles : [
      for principal in var.group_principals : {
        role      = role.role
        principal = principal
        condition = try(role.condition, null)
      }
    ]
  ]) : []

  project_custom_bindings = local.is_project_level ? flatten([
    for role in local.all_custom_roles_project : [
      for principal in var.group_principals : {
        role      = role.role
        principal = principal
        condition = role.condition
      }
    ]
  ]) : []

  folder_predefined_bindings = local.is_folder_level ? flatten([
    for role in local.all_predefined_roles : [
      for principal in var.group_principals : {
        role      = role.role
        principal = principal
        condition = role.condition
      }
    ]
  ]) : []

  folder_custom_bindings = local.is_folder_level ? flatten([
    for role in local.all_custom_roles_org : [
      for principal in var.group_principals : {
        role      = role.role
        principal = principal
        condition = role.condition
      }
    ]
  ]) : []

  jit_parent = local.is_project_level ? "projects/${var.project_id}" : (
    local.is_folder_level ? "folders/${var.folder_id}" : null
  )
  jit_resource = local.is_project_level ? "//cloudresourcemanager.googleapis.com/projects/${var.project_id}" : (
    local.is_folder_level ? "//cloudresourcemanager.googleapis.com/folders/${var.folder_id}" : null
  )
  jit_resource_type = local.is_project_level ? "cloudresourcemanager.googleapis.com/Project" : (
    local.is_folder_level ? "cloudresourcemanager.googleapis.com/Folder" : null
  )
  jit_roles = local.is_project_level ? concat([for role in local.all_predefined_roles : role.role], [for role in local.all_custom_roles_project : role.role]) : (
    local.is_folder_level ? concat([for role in local.all_predefined_roles : role.role], [for role in local.all_custom_roles_org : role.role]) : []
  )
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
  for_each = local.is_project_level && !var.jit_enabled ? { for binding in local.project_predefined_bindings : "${binding.role}-${binding.principal}-${sha1(jsonencode(try(binding.condition, null)))}" => binding } : {}

  project = var.project_id
  role    = each.value.role
  member  = each.value.principal

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [each.value.condition]
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Assign custom roles at project level
resource "google_project_iam_member" "custom_role" {
  for_each = local.is_project_level && !var.jit_enabled ? { for binding in local.project_custom_bindings : "${binding.role}-${binding.principal}-${sha1(jsonencode(try(binding.condition, null)))}" => binding } : {}

  project = var.project_id
  role    = each.value.role
  member  = each.value.principal

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [each.value.condition]
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_project_iam_custom_role.custom_role]
}

# Assign predefined roles at folder level
resource "google_folder_iam_member" "predefined_role" {
  for_each = local.is_folder_level && !var.jit_enabled ? { for binding in local.folder_predefined_bindings : "${binding.role}-${binding.principal}-${sha1(jsonencode(try(binding.condition, null)))}" => binding } : {}

  folder = var.folder_id
  role   = each.value.role
  member = each.value.principal

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [each.value.condition]
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Assign custom roles at folder level
resource "google_folder_iam_member" "custom_role" {
  for_each = local.is_folder_level && !var.jit_enabled ? { for binding in local.folder_custom_bindings : "${binding.role}-${binding.principal}-${sha1(jsonencode(try(binding.condition, null)))}" => binding } : {}

  folder = var.folder_id
  role   = each.value.role
  member = each.value.principal

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [each.value.condition]
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_organization_iam_custom_role.custom_role]
}

resource "google_privileged_access_manager_entitlement" "jit" {
  count = var.jit_enabled && (local.is_project_level || local.is_folder_level) && length(var.group_principals) > 0 && length(local.jit_roles) > 0 ? 1 : 0

  entitlement_id       = "${var.jit_entitlement_prefix}-${substr(sha256(join(",", sort(concat([local.jit_parent], var.group_principals, local.jit_roles)))), 0, 24)}"
  location             = "global"
  parent               = local.jit_parent
  max_request_duration = "${var.jit_max_activation_duration_seconds}s"

  dynamic "requester_justification_config" {
    for_each = var.jit_require_justification ? [1] : []
    content {
      unstructured {}
    }
  }

  eligible_users {
    principals = var.group_principals
  }

  privileged_access {
    gcp_iam_access {
      dynamic "role_bindings" {
        for_each = toset(local.jit_roles)
        content {
          role = role_bindings.value
        }
      }
      resource      = local.jit_resource
      resource_type = local.jit_resource_type
    }
  }

  dynamic "approval_workflow" {
    for_each = length(var.jit_approval_group_principals) > 0 ? [1] : []
    content {
      manual_approvals {
        steps {
          approvals_needed = 1
          approvers {
            principals = var.jit_approval_group_principals
          }
        }
      }
    }
  }

  depends_on = [
    google_project_iam_custom_role.custom_role,
    google_organization_iam_custom_role.custom_role
  ]
}
