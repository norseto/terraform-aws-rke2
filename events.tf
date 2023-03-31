data "aws_iam_policy_document" "event_bus_role_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "ssm.amazonaws.com"
      ]
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
      variable = "ssm:resourceTag/Role"
      values   = ["control-plane-seed", "control-plane-replica", "agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/ClusterName"
      values   = [local.base_name]
    }
  }
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
      "arn:aws:ssm:${local.region_name}:*:document/AWS-RunShellScript",
      aws_ssm_document.control_rke2.arn,
      aws_ssm_document.restore_server.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "ssm:ListCommands",
      "ssm:ListCommandInvocations"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ssm_run_command_role" {
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

resource "aws_cloudwatch_event_rule" "delete_node" {
  count = local.event_bus ? 1 : 0

  name        = "${local.base_name}-delete-node"
  description = "Delete terminated instance from Kubernetes cluster"

  event_pattern = jsonencode({
    "source" : ["aws.autoscaling"],
    "detail-type" : ["EC2 Instance Terminate Successful"]
    "detail" : {
      "AutoScalingGroupName" : local.asg_groupnames
    }
  })
  role_arn = aws_iam_role.ssm_run_command_role.arn
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_cloudwatch_event_target" "delete_node_cmd" {
  count = local.event_bus ? 1 : 0

  arn      = "arn:aws:ssm:${local.region_name}::document/AWS-RunShellScript"
  rule     = aws_cloudwatch_event_rule.delete_node[0].name
  role_arn = aws_iam_role.ssm_run_command_role.arn

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
