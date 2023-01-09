# node\_pool
Creates
- Autoscaling Group for agent nodes
- (Spot)Fleet for the first control plane node(seed)
- (Spot)Fleet for the other control plane node

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | terraform-aws-modules/autoscaling/aws | 6.5.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_fleet.ondemand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_fleet) | resource |
| [aws_ec2_fleet.spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_fleet) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocate_public_ip"></a> [allocate\_public\_ip](#input\_allocate\_public\_ip) | allocate public IP | `bool` | `true` | no |
| <a name="input_extra_ssh_keys"></a> [extra\_ssh\_keys](#input\_extra\_ssh\_keys) | extra ssh keys | `list(string)` | `[]` | no |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | IAM instance profile arn | `string` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | default instance type | `list(string)` | <pre>[<br>  "t3a.medium"<br>]</pre> | no |
| <a name="input_placement_group"></a> [placement\_group](#input\_placement\_group) | The name of the placement group into which you'll launch your instances, if any | `string` | `null` | no |
| <a name="input_pools"></a> [pools](#input\_pools) | node pool configurations. | <pre>list(object({<br>    name = string<br>    # 1 will be used for seed control plane, desired for other control plane.<br>    min_size         = number<br>    max_size         = number<br>    desired_capacity = number<br>    instance_types   = list(string)<br>    cpu_credits      = optional(string, "standard")<br>    volume_size      = optional(number, 20)<br>    # For control plane, spot will be used when spot_max_price is set.<br>    instances_distribution = object({<br>      on_demand_base_capacity                  = optional(number)<br>      on_demand_allocation_strategy            = optional(string)<br>      on_demand_percentage_above_base_capacity = optional(number)<br>      spot_allocation_strategy                 = optional(string)<br>      spot_max_price                           = optional(string)<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix | `string` | `""` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | security groups | `list(string)` | `[]` | no |
| <a name="input_single"></a> [single](#input\_single) | true if should be a single node. it is used when use\_asg is false. true for seed control plane. | `bool` | `false` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | instance ssh key name | `string` | `""` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | subnet ids | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags | `map(string)` | `{}` | no |
| <a name="input_target_group_arns"></a> [target\_group\_arns](#input\_target\_group\_arns) | loadbalancer target groups for control plane | `list(string)` | `[]` | no |
| <a name="input_use_asg"></a> [use\_asg](#input\_use\_asg) | true if asg should be used. true for agent servers, false for control planes. | `bool` | `false` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | user data | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arns"></a> [autoscaling\_group\_arns](#output\_autoscaling\_group\_arns) | List of arn of autoscaling group generated |
| <a name="output_autoscaling_group_ids"></a> [autoscaling\_group\_ids](#output\_autoscaling\_group\_ids) | List of id of autoscaling group generated |
