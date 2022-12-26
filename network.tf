module "cluster_server_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name            = "${local.base_name}-cluster-server-sg"
  description     = "Security group for Kubernetes servers of ${local.cluster_name}"
  vpc_id          = local.vpc_id
  use_name_prefix = true
  ingress_with_cidr_blocks = concat([
    for b in local.api_endpoint_ip_white_list :
    {
      from_port : 6443
      to_port : 6443
      protocol : 6
      description : "Kubernetes API for external clients"
      cidr_blocks : b
    }
    ], [
    {
      from_port : 9345
      to_port : 9345
      protocol : 6
      description : "internal Kubernetes API for cluster nodes"
      cidr_blocks : local.vpc_cidr
    },
    {
      from_port : 6443
      to_port : 6443
      protocol : 6
      description : "internal Kubernetes API for cluster nodes"
      cidr_blocks : local.vpc_cidr
    }
  ])
}

module "inter_cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name            = "${local.base_name}-inter-cluster-sg"
  description     = "Security group for cluster inter-nodes and LB."
  vpc_id          = local.vpc_id
  use_name_prefix = true
  ingress_with_self = [
    { rule : "all-all" }
  ]
  egress_with_cidr_blocks = [
    {
      rule : "all-all"
      cidr_blocks : "0.0.0.0/0"
    }
  ]
}

# Create a new load balancer for Kube-API and cluster server
resource "aws_lb" "api_nlb" {
  count = local.use_eip ? 0 : 1

  name = "${local.base_name}-api-nlb"

  subnets            = local.api_endpoint_subnet_ids
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = true

  internal = false

  tags = merge(local.tags, {
    ClusterName : local.base_name
    Role : "control-plane"
  })
}

# Create a new load balancer for Kube-API and cluster server
resource "aws_lb" "cluster_nlb" {
  count = local.use_eip ? 0 : 1

  name = "${local.base_name}-internal-nlb"

  subnets            = local.control_plane.subnet_ids
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = true

  internal = true

  tags = merge(local.tags, {
    ClusterName : local.base_name
    Role : "control-plane"
  })
}

resource "aws_lb_target_group" "cluster_server" {
  count = local.use_eip ? 0 : 1

  name     = "${local.base_name}-cluster-server-tg"
  port     = 9345
  protocol = "TCP"
  vpc_id   = local.vpc_id

  deregistration_delay = 120
  health_check {
    protocol            = "TCP"
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_lb_target_group" "cluster_api" {
  count = local.use_eip ? 0 : 1

  name     = "${local.base_name}-cluster-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = local.vpc_id

  deregistration_delay = 120
  health_check {
    protocol            = "TCP"
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_lb_target_group" "kube_api" {
  count = local.use_eip ? 0 : 1

  name     = "${local.base_name}-kube-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = local.vpc_id

  deregistration_delay = 120
  health_check {
    protocol            = "TCP"
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_lb_listener" "cluster_server" {
  count = local.use_eip ? 0 : 1

  load_balancer_arn = aws_lb.cluster_nlb[0].arn
  port              = "9345"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster_server[0].arn
  }
}

resource "aws_lb_listener" "cluster_api" {
  count = local.use_eip ? 0 : 1

  load_balancer_arn = aws_lb.cluster_nlb[0].arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster_api[0].arn
  }
}

resource "aws_lb_listener" "kube_api" {
  count = local.use_eip ? 0 : 1

  load_balancer_arn = aws_lb.api_nlb[0].arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api[0].arn
  }
}

resource "aws_iam_policy" "targetgroup_register_policy" {
  count = local.use_eip ? 0 : 1

  name        = "${local.base_name}-targetgroup-register-policy"
  path        = "/"
  description = "Policy for TargetGroup registration"

  policy = data.aws_iam_policy_document.targetgroup_register_policy[0].json
}

data "aws_iam_policy_document" "targetgroup_register_policy" {
  count = local.use_eip ? 0 : 1

  statement {
    sid = "1"

    actions = [
      "elasticloadbalancing:RegisterTargets"
    ]

    resources = [
      aws_lb_target_group.cluster_server[0].arn,
      aws_lb_target_group.cluster_api[0].arn,
      aws_lb_target_group.kube_api[0].arn
    ]
  }
}
