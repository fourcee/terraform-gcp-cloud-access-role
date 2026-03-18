# Examples

This directory contains example configurations for using the GCP IAM Assignment Terraform module.

## Examples Overview

### 1. Project-Level IAM with Predefined Roles (`examples.tf` - Example 1)

Demonstrates assigning GCP predefined roles to group principals at the project level. This is the simplest use case.

**Use when:**
- You only need to assign existing GCP roles
- Working at the project level
- No custom permissions needed

### 2. Project-Level IAM with Custom Roles (`examples.tf` - Example 2)

Shows how to create and assign custom IAM roles with specific permissions at the project level.

**Use when:**
- You need custom permissions that aren't covered by predefined roles
- Want to implement least-privilege access
- Working at the project level

### 3. Folder-Level IAM Assignment (`examples.tf` - Example 3)

Demonstrates IAM assignments at the folder level with both predefined and custom roles.

**Use when:**
- Managing permissions across multiple projects in a folder
- Need organization-wide custom roles
- Implementing hierarchical access control

### 4. Multiple Principals with Roles (`examples.tf` - Example 4)

Shows how multiple group principals can be assigned multiple roles efficiently.

**Use when:**
- Managing multiple teams with different access levels
- All groups need the same set of roles

## How to Use

1. Copy one of the examples to your Terraform configuration
2. Update the values:
   - `project_id` or `folder_id` and `organization_id`
   - `predefined_roles` with your desired GCP roles and IAM conditions
   - `custom_roles` with your custom role definitions and IAM conditions
   - `group_principals` with your Google Group email addresses
3. Run `terraform init` and `terraform plan` to review changes
4. Apply with `terraform apply` when ready

## Notes

- All examples use the module source as `github.com/fourcee/terraform-gcp-cloud-access-role`
- You may need to adjust this based on your module installation method
- Ensure you have appropriate GCP permissions to create and assign roles
- Group principals should be in the format `group:name@domain.com`
