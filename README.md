# terraform-gcp-cloud-access-role

A Terraform module for deploying GCP IAM role assignments. This module allows you to create custom IAM roles and assign both predefined and custom roles to group and user principals at either the project or folder level, and optionally create PAM JIT entitlements instead of direct IAM assignments.

## Features

- Create custom IAM roles with specified permissions
- Assign predefined GCP roles to group and user principals with optional IAM conditions
- Assign custom roles to group and user principals with optional IAM conditions
- Support for both project-level and folder-level IAM assignments
- Optional JIT PAM entitlements using `google_privileged_access_manager_entitlement`

## Usage

See the [examples directory](./examples) for complete usage examples.

### Project-Level IAM Assignment

```hcl
module "iam_assignment" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project"

  predefined_roles = [
    {
      role = "roles/viewer"
    },
    {
      role = "roles/storage.objectViewer"
    },
    {
      role = "roles/logging.viewer"
      condition = {
        title       = "AuthenticatedOnly"
        description = "Restrict logging viewing to authenticated requests"
        expression  = "request.auth != null"
      }
    }
  ]

  custom_roles = [
    {
      role_id     = "customAppRole"
      title       = "Custom Application Role"
      description = "Custom role for application-specific permissions"
      permissions = [
        "storage.buckets.get",
        "storage.buckets.list",
        "compute.instances.list"
      ]
      stage = "GA"
      condition = {
        title       = "ProdProjectOnly"
        description = "Allow custom role only until a specific expiry date"
        expression  = "request.time < timestamp('2030-01-01T00:00:00Z')"
      }
    }
  ]

  group_principals = [
    "group:developers@example.com",
    "group:ops@example.com"
  ]

  user_principals = [
    "user:alice@example.com"
  ]
}
```

### Folder-Level IAM Assignment

```hcl
module "iam_assignment" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  folder_id       = "123456789012"
  organization_id = "987654321098"

  predefined_roles = [
    {
      role = "roles/resourcemanager.folderViewer"
      condition = {
        title       = "FolderReadOnly"
        description = "Read-only folder access for authenticated requests"
        expression  = "request.auth != null"
      }
    }
  ]

  custom_roles = [
    {
      role_id     = "folderCustomRole"
      title       = "Folder Custom Role"
      description = "Custom role for folder-level permissions"
      permissions = [
        "resourcemanager.folders.get",
        "resourcemanager.folders.list"
      ]
      stage = "BETA"
      condition = {
        title       = "FolderScopedAccess"
        description = "Scope folder custom role assignments with condition"
        expression  = "request.time < timestamp('2030-01-01T00:00:00Z')"
      }
    }
  ]

  group_principals = [
    "group:folder-admins@example.com"
  ]

  user_principals = [
    "user:security-admin@example.com"
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| google | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| predefined_roles | List of GCP predefined roles and optional IAM conditions to assign to the group principals | <pre>list(object({<br>  role = string<br>  condition = optional(object({<br>    title       = string<br>    description = string<br>    expression  = string<br>  }))<br>}))</pre> | `[]` | no |
| custom_roles | List of custom GCP roles to create and assign | <pre>list(object({<br>  role_id     = string<br>  title       = string<br>  description = string<br>  permissions = list(string)<br>  stage       = string<br>  condition = optional(object({<br>    title       = string<br>    description = string<br>    expression  = string<br>  }))<br>}))</pre> | `[]` | no |
| group_principals | List of GCP group principals (e.g., 'group:example@example.com') to assign roles to | `list(string)` | `[]` | no |
| user_principals | List of GCP user principals (e.g., 'user:example@example.com') to assign roles to | `list(string)` | `[]` | no |
| project_id | The GCP project ID to assign permissions at. Must provide either project_id or folder_id. | `string` | `null` | no |
| folder_id | The GCP folder ID to assign permissions at. Must provide either project_id or folder_id. | `string` | `null` | no |
| organization_id | The GCP organization ID. Required when using folder_id to create custom roles at organization level. | `string` | `null` | no |
| jit_enabled | Whether to create JIT PAM entitlements instead of regular IAM assignments. | `bool` | `false` | no |
| jit_require_justification | Whether PAM activation requests must include justification. | `bool` | `false` | no |
| jit_max_activation_duration_seconds | Maximum PAM activation duration, in seconds. | `number` | `3600` | no |
| jit_approval_group_principals | List of group principals that can approve PAM activation requests. If empty, no approval workflow is configured. | `list(string)` | `[]` | no |
| jit_approval_user_principals | List of user principals that can approve PAM activation requests. If empty, no approval workflow is configured. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| custom_role_ids | Map of custom role IDs to their full resource names |
| custom_role_names | Map of custom role IDs to their names |
| assigned_roles | List of all roles that have been assigned |
| assigned_principals | List of all principals that have been assigned roles |
| jit_reference_id | The created PAM entitlement ID when jit_enabled is true |

## Notes

- You must provide either `project_id` or `folder_id`, but not both
- When using `folder_id`, you must also provide `organization_id` if creating custom roles
- Custom roles at the folder level are created at the organization level and then assigned to the folder
- Custom role stages can be: `ALPHA`, `BETA`, `GA`, or `DEPRECATED`
- Group principals should be in the format `group:groupname@domain.com`
- User principals should be in the format `user:username@domain.com`
- Predefined roles should use the full role name (e.g., `roles/viewer`) in the `role` field
- IAM conditions are optional for predefined and custom role assignments; if provided, include `title`, `description`, and `expression`
- When `jit_enabled = true`, regular IAM member assignments are skipped and a PAM entitlement is created instead
- The PAM `requester_justification_config` block is always configured; when `jit_require_justification = false`, the entitlement uses `not_mandatory`
- If both `jit_approval_group_principals` and `jit_approval_user_principals` are empty, no approval workflow is configured (self-enabled activation)

## License

See the LICENSE file for details.
