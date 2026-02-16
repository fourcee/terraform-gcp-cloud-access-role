# Example configurations for the GCP IAM Assignment Module

# Example 1: Project-level IAM assignment with predefined roles only
module "project_iam_predefined" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  predefined_roles = [
    "roles/viewer",
    "roles/storage.objectViewer",
    "roles/logging.viewer"
  ]

  group_principals = [
    "group:developers@example.com",
    "group:analysts@example.com"
  ]
}

# Example 2: Project-level IAM assignment with custom roles
module "project_iam_custom" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  predefined_roles = [
    "roles/viewer"
  ]

  custom_roles = [
    {
      role_id     = "customAppRole"
      title       = "Custom Application Role"
      description = "Custom role for application-specific permissions"
      permissions = [
        "storage.buckets.get",
        "storage.buckets.list",
        "storage.objects.get",
        "storage.objects.list",
        "compute.instances.list",
        "compute.instances.get"
      ]
      stage = "GA"
    },
    {
      role_id     = "customDataRole"
      title       = "Custom Data Access Role"
      description = "Custom role for data access"
      permissions = [
        "bigquery.datasets.get",
        "bigquery.tables.list",
        "bigquery.tables.get",
        "bigquery.tables.getData"
      ]
      stage = "GA"
    }
  ]

  group_principals = [
    "group:app-users@example.com"
  ]
}

# Example 3: Folder-level IAM assignment
module "folder_iam_assignment" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  folder_id       = "123456789012"
  organization_id = "987654321098"

  predefined_roles = [
    "roles/resourcemanager.folderViewer",
    "roles/viewer"
  ]

  custom_roles = [
    {
      role_id     = "folderCustomRole"
      title       = "Folder Custom Role"
      description = "Custom role for folder-level permissions"
      permissions = [
        "resourcemanager.folders.get",
        "resourcemanager.folders.list",
        "resourcemanager.projects.get",
        "resourcemanager.projects.list"
      ]
      stage = "GA"
    }
  ]

  group_principals = [
    "group:folder-admins@example.com",
    "group:project-viewers@example.com"
  ]
}

# Example 4: Multiple principals with different roles
# NOTE: This example demonstrates the Cartesian product behavior where ALL principals
# receive ALL roles. In this case, all three groups will receive viewer, editor, and owner roles.
# For production use, consider creating separate module calls for different access levels.
module "multi_principal_iam" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  # WARNING: roles/owner grants full administrative access. Use sparingly and only for trusted admins.
  # Consider using more restricted roles like roles/editor or custom roles with specific permissions.
  predefined_roles = [
    "roles/viewer",
    "roles/editor",
    "roles/owner"
  ]

  group_principals = [
    "group:viewers@example.com",
    "group:editors@example.com",
    "group:admins@example.com"
  ]
}

# Example 5: Different roles for different groups (recommended approach)
# Create separate module calls to assign different roles to different groups
module "viewer_access" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  predefined_roles = ["roles/viewer"]

  group_principals = [
    "group:viewers@example.com"
  ]
}

module "editor_access" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  predefined_roles = [
    "roles/viewer",
    "roles/editor"
  ]

  group_principals = [
    "group:editors@example.com"
  ]
}

module "admin_access" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project-123"

  # WARNING: roles/owner grants full administrative access. Use sparingly.
  predefined_roles = [
    "roles/viewer",
    "roles/editor",
    "roles/owner"
  ]

  group_principals = [
    "group:admins@example.com"
  ]
}
