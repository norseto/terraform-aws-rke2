data "aws_iam_policy_document" "event_bus_role_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "event_bus_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:${local.region_name}:*:instance/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Role"
      values   = ["control-plane-seed", "control-plane-replica", "agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ClusterName"
      values   = [local.base_name]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["ssm:SendCommand"]
    resources = [
      "arn:aws:ssm:${local.region_name}:*:document/AWS-RunShellScript"
    ]
  }
}

resource "aws_iam_role" "event_bus_run_command_role" {
  count = local.event_bus_agent ? 1 : 0

  name               = "${local.base_name}-run-command-role"
  assume_role_policy = data.aws_iam_policy_document.event_bus_role_assume_policy.json
  inline_policy {
    name   = "${local.base_name}-invoke-run-command"
    policy = data.aws_iam_policy_document.event_bus_role_policy.json
  }
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_cloudwatch_event_rule" "delete_agent" {
  count = local.event_bus_agent ? 1 : 0

  name        = "${local.base_name}-delete-agent-node"
  description = "Delete terminated instance from Kubernetes cluster"

  event_pattern = jsonencode({
    "source" : ["aws.autoscaling"],
    "detail-type" : ["EC2 Instance Terminate Successful"]
    "detail" : {
      "AutoScalingGroupName" : local.agent_asg_groupnames
    }
  })
  role_arn = aws_iam_role.event_bus_run_command_role[0].arn
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_cloudwatch_event_target" "delete_agent_cmd" {
  count = local.event_bus_agent ? 1 : 0

  arn      = "arn:aws:ssm:${local.region_name}::document/AWS-RunShellScript"
  rule     = aws_cloudwatch_event_rule.delete_agent[0].name
  role_arn = aws_iam_role.event_bus_run_command_role[0].arn

  input_transformer {
    input_paths = {
      instance : "$.detail.EC2InstanceId"
    }
    input_template = <<EOM
{
  "commands" : [
    "kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml delete node -l node.kubernetes.io/instance-id=<instance>"
  ],
  "workingDirectory" : ["/etc/rancher/rke2"]
}
EOM
  }
  run_command_targets {
    key    = "tag:ClusterName"
    values = [local.base_name]
  }
  run_command_targets {
    key    = "tag:Role"
    values = ["control-plane-seed", "control-plane-replica"]
  }
  retry_policy {
    maximum_event_age_in_seconds = 1800
    maximum_retry_attempts       = 3
  }
}
