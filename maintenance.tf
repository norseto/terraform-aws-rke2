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

resource "aws_ssm_document" "restore_rke2" {
  name            = "${local.base_name}-restore-rke2"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: |
  Restore RKE2 server. Use Tags: 
  ClusterName = ${local.base_name} and Role = control-plane-seed
parameters:
  backup:
    type: "String"
    description: "(Required) Backup file it should be on ther server datadir or S3 backups"
  dataDir:
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
    - "rke2 server --cluster-reset --cluster-reset-restore-path={{ backup }}"
    - "systemctl start rke2-server.service"
- action: aws:runShellScript
  name: restoreRKE2Replica
  inputs:
    runCommand:
    - "systemctl is-enabled rke2-server.service && \\"
    - "test ! -f /etc/rancher/rke2/control-plane-init.yaml || exit 0"
    - "systemctl stop rke2-agent.service"
    - "sleep 5"
    - "rm -rf {{ dataDir }}"
    - "systemctl start rke2-server.service"
DOC
  tags = {
    Cluster : local.base_name
  }
}
