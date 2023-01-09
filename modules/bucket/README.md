# bucket
Create S3 bucket that contents in/out.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.6.0 |
| <a name="module_read_only_policy"></a> [read\_only\_policy](#module\_read\_only\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.3.0 |
| <a name="module_read_write_policy"></a> [read\_write\_policy](#module\_read\_write\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.read_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket"></a> [bucket](#input\_bucket) | bucket name | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | base name. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags | `map(string)` | `{}` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | enable versioning | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | bucket |
| <a name="output_read_only_policy"></a> [read\_only\_policy](#output\_read\_only\_policy) | bucket read-only policy |
| <a name="output_read_write_policy"></a> [read\_write\_policy](#output\_read\_write\_policy) | bucket read-write policy |
