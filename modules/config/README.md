# config
Configuration files.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_object.configs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.dummies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_server_taint"></a> [add\_server\_taint](#input\_add\_server\_taint) | True if add server taint | `bool` | `false` | no |
| <a name="input_bucket_id"></a> [bucket\_id](#input\_bucket\_id) | bucket id | `string` | n/a | yes |
| <a name="input_bucket_region"></a> [bucket\_region](#input\_bucket\_region) | bucket region | `string` | n/a | yes |
| <a name="input_disabled_server_charts"></a> [disabled\_server\_charts](#input\_disabled\_server\_charts) | Specify disabled server charts | `list(string)` | `[]` | no |
| <a name="input_server_fqdn"></a> [server\_fqdn](#input\_server\_fqdn) | server fqdn | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags. | `map(string)` | `{}` | no |
| <a name="input_tls_san"></a> [tls\_san](#input\_tls\_san) | tls sans | `list(string)` | `[]` | no |
| <a name="input_token"></a> [token](#input\_token) | server token | `string` | `""` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | enable versioning | `bool` | `true` | no |

## Outputs

No outputs.
