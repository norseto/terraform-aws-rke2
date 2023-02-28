
data "aws_iam_policy_document" "restore_policy" {
  statement {
    actions = [
      "ssm:StartAutomationExecution"
    ]
    resources = [
      replace("${aws_ssm_document.restore_rke2.arn}:*", ":document/", ":automation-definition/")
    ]
  }
}

module "restore_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.0"

  name   = "${local.base_name}-restore-rke2-policy"
  policy = data.aws_iam_policy_document.restore_policy.json

  tags = {
    Name : "${local.base_name}-restore-rke2-policy"
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "restore_rke2" {
  name            = "${local.base_name}-restore-rke2"
  document_format = "YAML"
  document_type   = "Automation"
  target_type     = "/AWS::AWS::EC2::Instance"

  content = <<DOC
description: |-
  ### Document name - ${local.base_name}-restore-rke2
  ## What does this document do?
  Restore RKE2 ${local.base_name} cluster from a backup.
  ## Input Parameters
  * Backup: (Required) Backup file name to restore.
  * DataDir: (Optional) Data directory path.
  ## Output Parameters
  * StartRestore.Output: Restore result.
schemaVersion: '0.3'
assumeRole: "${aws_iam_role.ssm_run_command_role.arn}"
outputs:
- StopAgents.Output
- StopServers.Output
- RestoreSeed.Output
- CleanupReplica.Output
- RebootAgents.Output
- StartSeed.Output
- StartReplicas.Output
parameters:
  Backup:
    type: "String"
    description: "(Required) Backup file it should be on ther server datadir or S3 backups"
  DataDir:
    type: "String"
    description: "(Optional) Data directory"
    default: "/var/lib/rancher/rke2/server/db"

mainSteps:
- name: StopAgents
  action: 'aws:runCommand'
  description: |
    ## StopAgents
    Stop RKE2 agents of the all cluster node.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.control_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Action: stop
      TargetType: agent
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "agent" ]

- name: StopServers
  action: 'aws:runCommand'
  description: |
    ## StopServers
    Stop RKE2 servers of the all cluster node.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.control_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Action: stop
      TargetType: server
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-replica", "control-plane-seed" ]

- name: RestoreSeed
  action: 'aws:runCommand'
  description: |
    ## RestoreSeed
    Start restore seed.
    ## outputs
    * Output: Result
  timeoutSeconds: 1800
  maxAttempts: 3
  onFailure: Abort

  inputs:
    DocumentName: ${aws_ssm_document.restore_server.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Backup: '{{ Backup }}'
      DataDir: '{{ DataDir }}'
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-seed" ]

- name: CleanupReplica
  action: 'aws:runCommand'
  description: |
    ## CleanupReplica
    Cleanup old data in replicas.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort

  inputs:
    DocumentName: ${aws_ssm_document.restore_server.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Backup: '{{ Backup }}'
      DataDir: '{{ DataDir }}'
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-replica" ]

- name: StartSeed
  action: 'aws:runCommand'
  description: |
    ## StartSeed
    Start RKE2 seed server of the cluster.
    ## outputs
    * Output: Result
  timeoutSeconds: 3600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.control_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Action: start
      TargetType: server
      CleanNodes: 'yes'
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-seed"]

- name: StartReplicas
  action: 'aws:runCommand'
  description: |
    ## StartServers
    Start RKE2 replica servers of the cluster.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.control_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Action: start
      TargetType: server
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: ["control-plane-replica" ]

- name: RebootAgents
  action: 'aws:runCommand'
  description: |
    ## RebootAgents
    Reboot RKE2 agents of the all cluster node.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.control_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
    Parameters:
      Action: reboot
      TargetType: agent
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "agent" ]
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "control_rke2" {
  name            = "${local.base_name}-control-rke2"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Control RKE2 service. Can start, stop, restart
parameters:
  Action:
    type: String
    description: "(Required) Action to do"
    allowedValues:
    - start
    - stop
    - restart
    - reboot
  TargetType:
    type: String
    description: "(Required) Which target type server or agent"
    allowedValues:
    - server
    - agent
  CleanNodes:
    type: String
    description: "(Optional) Delete nodes except the target node"
    allowedValues:
    - 'yes'
    - 'no'
    default: 'no'
mainSteps:
- action: aws:runShellScript
  name: DoServerAction
  isEnd: true
  inputs:
    runCommand:
    - "if [ 'reboot' = '{{ Action }}' ] ; then"
    - "  if [ -e /etc/rancher/rke2/reboot.tmp ] ; then rm -f /etc/rancher/rke2/reboot.tmp ; exit 0; fi"
    - "  touch /etc/rancher/rke2/reboot.tmp"
    - "  exit 194"
    - "fi"
    - "systemctl {{ Action }} rke2-{{ TargetType }}.service"
    - "test 'yes' = '{{ CleanNodes }}' || exit 0"
    - "for h in $(kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get node -ojsonpath='{.items[*].metadata.name}') ; "
    - "do if [ $h != $(hostname) ] ; then kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml delete node $h; fi ; done"
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "restore_server" {
  name            = "${local.base_name}-restore-server"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Restore RKE2 server. It is not recommended that you run this command direct.
  Use ${local.base_name}-restore-rke2 instead.
parameters:
  Backup:
    type: String
    description: "(Required) Backup file it should be on ther server datadir or S3 backups"
  DataDir:
    type: String
    description: "(Optional) Data directory"
    default: "/var/lib/rancher/rke2/server/db"
mainSteps:
- action: aws:runShellScript
  name: restoreRKE2Seed
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && \\"
    - "test -f /etc/rancher/rke2/control-plane-init.yaml || exit 0"
    - "if [ -e /etc/rancher/rke2/restore.tmp ] ; then rm -f /etc/rancher/rke2/restore.tmp ; exit 0; fi"
    - "rke2 server --cluster-reset --cluster-reset-restore-path={{ Backup }}"
    - "touch /etc/rancher/rke2/restore.tmp"
    - "/usr/local/bin/rke2-killall.sh"
    - "exit 194"
- action: aws:runShellScript
  name: restoreRKE2Replica
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && \\"
    - "test ! -f /etc/rancher/rke2/control-plane-init.yaml || exit 0"
    - "if [ -e /etc/rancher/rke2/restore.tmp ] ; then rm -f /etc/rancher/rke2/restore.tmp ; exit 0; fi"
    - "rm -rf {{ DataDir }}"
    - "touch /etc/rancher/rke2/restore.tmp"
    - "exit 194"
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "take_snapshot" {
  name            = "${local.base_name}-snapshot-rke2"
  document_format = "YAML"
  document_type   = "Automation"
  target_type     = "/AWS::AWS::EC2::Instance"

  content = <<DOC
description: |-
  ### Document name - ${local.base_name}-snapshot-rke2
  ## What does this document do?
  Take snapshot RKE2 ${local.base_name} cluster.
  ## Input Parameters
  * Backup: (Required) Backup file name to restore.
  ## Output Parameters
  * TakeSnapshot.Output: Take snapshot result.
schemaVersion: '0.3'
assumeRole: "${aws_iam_role.ssm_run_command_role.arn}"
outputs:
- TakeSnapshot.Output
parameters:
  Backup:
    type: "String"
    description: "(Required) Backup name"

mainSteps:
- name: TakeSnapshot
  action: 'aws:runCommand'
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: 'AWS-RunShellScript'
    Parameters:
      commands:
      - "rke2 etcd-snapshot save --name {{ Backup }}"
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-seed" ]
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "update_kubeconfig" {
  name            = "${local.base_name}-updateconfig-rke2"
  document_type   = "Automation"
  document_format = "YAML"
  target_type     = "/AWS::AWS::EC2::Instance"

  content = <<DOC
description: |-
  ### Document name - ${local.base_name}-updateconfig-rke2
  ## What does this document do?
  Get kubeconfig file to S3 bucket for ${local.base_name} cluster.
schemaVersion: '0.3'
assumeRole: "${aws_iam_role.ssm_run_command_role.arn}"
outputs:
- UpdateConfig.Output
parameters: {}
mainSteps:
- name: UpdateConfig
  action: 'aws:runCommand'
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: 'AWS-RunShellScript'
    Parameters:
      commands:
      - "sed -e 's/127.0.0.1/${local.api_endpoint}/g' /etc/rancher/rke2/rke2.yaml > /etc/rancher/rke2/rke2_fqdn.yaml"
      - "aws s3 cp /etc/rancher/rke2/rke2_fqdn.yaml s3://${module.bucket.bucket.s3_bucket_id}/config/kubeconfig.yaml"
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "control-plane-seed" ]
DOC
  tags = {
    Cluster : local.base_name
  }
}
