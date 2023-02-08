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
- RestoreSeed.Output
- RestoreReplica.Output
- RestartAgent.Output
parameters:
  Backup:
    type: "String"
    description: "(Required) Backup file it should be on ther server datadir or S3 backups"
  DataDir:
    type: "String"
    description: "(Optional) Data directory"
    default: "/var/lib/rancher/rke2/server/db"
mainSteps:
- name: RestoreSeed
  action: 'aws:runCommand'
  description: |
    ## RestoreSeed
    Start restore seed automation
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
      Values: [ "control-plane-seed" ]

- name: RestoreReplica
  action: 'aws:runCommand'
  description: |
    ## RestoreReplica
    Start restore replica automation
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

- name: RestartAgent
  action: 'aws:runCommand'
  description: |
    ## RestartAgent
    Start restart agents automation
    ## outputs
    * Output: Result
  timeoutSeconds: 600
  maxAttempts: 3
  onFailure: Abort

  inputs:
    DocumentName: ${aws_ssm_document.restart_rke2.name}
    ServiceRoleArn: "${aws_iam_role.ssm_run_command_role.arn}"
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

resource "aws_ssm_document" "restart_rke2" {
  name            = "${local.base_name}-restart-rke2"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Restart RKE2 service. Use Tags: 
  ClusterName = ${local.base_name} and Role = agent/control-plane-seed/control-plane-replica
mainSteps:
- action: aws:runShellScript
  name: restartRKE2AgentService
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-agent.service && systemctl restart rke2-agent.service || true"
- action: aws:runShellScript
  name: restartRKE2ServerService
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && systemctl restart rke2-server.service || true"
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
    type: "String"
    description: "(Required) Backup file it should be on ther server datadir or S3 backups"
  DataDir:
    type: "String"
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
    - "sleep 15"
    - "rke2 server --cluster-reset --cluster-reset-restore-path={{ Backup }}"
    - "systemctl start rke2-server.service"
    - "sed -e 's/127.0.0.1/${local.api_endpoint}/g' /etc/rancher/rke2/rke2.yaml > /etc/rancher/rke2/rke2_fqdn.yaml"
    - "aws s3 cp /etc/rancher/rke2/rke2_fqdn.yaml s3://${module.bucket.bucket.s3_bucket_id}/config/kubeconfig.yaml"
- action: aws:runShellScript
  name: restoreRKE2Replica
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && \\"
    - "test ! -f /etc/rancher/rke2/control-plane-init.yaml || exit 0"
    - "systemctl stop rke2-agent.service"
    - "sleep 5"
    - "rm -rf {{ DataDir }}"
    - "systemctl start rke2-server.service"
DOC
  tags = {
    Cluster : local.base_name
  }
}
