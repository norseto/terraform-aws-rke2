# config
Configuration files.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14 |

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
| <a name="input_addon_config"></a> [addon\_config](#input\_addon\_config) | Addon configurations | <pre>object({<br>    aws_ebs_csi_driver = optional(string, "none")<br>  })</pre> | n/a | yes |
| <a name="input_api_endpoint"></a> [api\_endpoint](#input\_api\_endpoint) | API server endpoint | `string` | n/a | yes |
| <a name="input_bucket_id"></a> [bucket\_id](#input\_bucket\_id) | bucket id | `string` | n/a | yes |
| <a name="input_cloud_config"></a> [cloud\_config](#input\_cloud\_config) | Cloud configurations | <pre>object({<br>    eip_allocation_id = optional(string, "")<br>    zone_id           = optional(string, "")<br>    api_tg_arn        = optional(string, "")<br>    in_api_tg_arn     = optional(string, "")<br>    in_srv_tg_arn     = optional(string, "")<br>  })</pre> | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | cluster full name | `string` | n/a | yes |
| <a name="input_disabled_server_charts"></a> [disabled\_server\_charts](#input\_disabled\_server\_charts) | Specify disabled server charts | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | bucket region | `string` | n/a | yes |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | RKE2 version | `string` | `""` | no |
| <a name="input_server_fqdn"></a> [server\_fqdn](#input\_server\_fqdn) | server fqdn | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags. | `map(string)` | `{}` | no |
| <a name="input_tls_san"></a> [tls\_san](#input\_tls\_san) | tls sans | `list(string)` | `[]` | no |
| <a name="input_token"></a> [token](#input\_token) | server token | `string` | `""` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | enable versioning | `bool` | `true` | no |

## Outputs

No outputs.
