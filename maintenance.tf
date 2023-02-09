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
- StartAgents.Output
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

- name: StartAgents
  action: 'aws:runCommand'
  description: |
    ## StartAgents
    Start RKE2 agents of the all cluster node.
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
      TargetType: agent
    Targets:
    - Key: tag:ClusterName
      Values: [ "${local.base_name}" ]
    - Key: tag:Role
      Values: [ "agent" ]

- name: RefreshConfig
  action: 'aws:runCommand'
  description: |
    ## RefreshConfig
    Refresh kubeconfig file.
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort
  inputs:
    DocumentName: ${aws_ssm_document.update_kubeconfig.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
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
  TargetType:
    type: String
    description: "(Required) Which target type server or agent"
    allowedValues:
    - server
    - agent
mainSteps:
- action: aws:runShellScript
  name: StopServer
  isEnd: true
  inputs:
    runCommand:
    - "systemctl {{ Action }} rke2-{{ TargetType }}.service"
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
    - "/usr/local/bin/rke2-killall.sh"
    - "rm -rf {{ DataDir }}"
    - "rke2 server --cluster-reset --cluster-reset-restore-path={{ Backup }}"
- action: aws:runShellScript
  name: restoreRKE2Replica
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && \\"
    - "test ! -f /etc/rancher/rke2/control-plane-init.yaml || exit 0"
    - "rm -rf {{ DataDir }}"
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "take_snapshot" {
  name            = "${local.base_name}-snapshot-rke2"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Take RKE2 snapshot.
parameters:
  Name:
    type: String
    description: "The name of the snapshot"
mainSteps:
- action: aws:runShellScript
  name: StopServer
  isEnd: true
  inputs:
    runCommand:
    - "rke2 etcd-snapshot save --name {{ Name }}"
DOC
  tags = {
    Cluster : local.base_name
  }
}

resource "aws_ssm_document" "update_kubeconfig" {
  name            = "${local.base_name}-updateconfig-rke2"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Take RKE2 snapshot.
mainSteps:
- action: aws:runShellScript
  name: StopServer
  isEnd: true
  inputs:
    runCommand:
    - "sed -e 's/127.0.0.1/${local.api_endpoint}/g' /etc/rancher/rke2/rke2.yaml > /etc/rancher/rke2/rke2_fqdn.yaml"
    - "aws s3 cp /etc/rancher/rke2/rke2_fqdn.yaml s3://${module.bucket.bucket.s3_bucket_id}/config/kubeconfig.yaml"
DOC
  tags = {
    Cluster : local.base_name
  }
}
