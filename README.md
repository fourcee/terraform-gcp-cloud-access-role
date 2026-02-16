# terraform-gcp-cloud-access-role

A Terraform module for deploying GCP IAM role assignments. This module allows you to create custom IAM roles and assign both predefined and custom roles to group principals at either the project or folder level.

## Features

- Create custom IAM roles with specified permissions
- Assign predefined GCP roles to group principals
- Assign custom roles to group principals
- Support for both project-level and folder-level IAM assignments

## Usage

### Project-Level IAM Assignment

```hcl
module "iam_assignment" {
  source = "github.com/fourcee/terraform-gcp-cloud-access-role"

  project_id = "my-gcp-project"

  predefined_roles = [
    "roles/viewer",
    "roles/storage.objectViewer"
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
    }
  ]

  group_principals = [
    "group:developers@example.com",
    "group:ops@example.com"
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
    "roles/resourcemanager.folderViewer"
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
    }
  ]

  group_principals = [
    "group:folder-admins@example.com"
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| predefined_roles | List of GCP predefined roles to assign to the group principals | `list(string)` | `[]` | no |
| custom_roles | List of custom GCP roles to create and assign | <pre>list(object({<br>  role_id     = string<br>  title       = string<br>  description = string<br>  permissions = list(string)<br>  stage       = string<br>}))</pre> | `[]` | no |
| group_principals | List of GCP group principals (e.g., 'group:example@example.com') to assign roles to | `list(string)` | `[]` | no |
| project_id | The GCP project ID to assign permissions at. Must provide either project_id or folder_id. | `string` | `null` | no |
| folder_id | The GCP folder ID to assign permissions at. Must provide either project_id or folder_id. | `string` | `null` | no |
| organization_id | The GCP organization ID. Required when using folder_id to create custom roles at organization level. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| custom_role_ids | Map of custom role IDs to their full resource names |
| custom_role_names | Map of custom role IDs to their names |
| assigned_roles | List of all roles that have been assigned |
| assigned_principals | List of all principals that have been assigned roles |

## Notes

- You must provide either `project_id` or `folder_id`, but not both
- When using `folder_id`, you must also provide `organization_id` if creating custom roles
- Custom roles at the folder level are created at the organization level and then assigned to the folder
- Custom role stages can be: `ALPHA`, `BETA`, `GA`, or `DEPRECATED`
- Group principals should be in the format `group:groupname@domain.com`
- Predefined roles should use the full role name (e.g., `roles/viewer`)

## License

See the LICENSE file for details.