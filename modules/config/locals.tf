locals {
  bucket_id     = var.bucket_id
  bucket_region = var.bucket_region
  token         = var.token
  server_fqdn   = var.server_fqdn
  tls_san       = compact(concat(var.tls_san, [var.server_fqdn]))
  rke2_version  = var.rke2_version
  api_endpoint  = var.api_endpoint
  versioning    = var.versioning
  cloud_config  = var.cloud_config
  addon_config  = var.addon_config
  tags          = var.tags

  configs = [
    { name : "control-plane.yaml", content_type : "application/x-yaml", empty : false },
    { name : "control-plane-init.yaml", content_type : "application/x-yaml", empty : false },
    { name : "agent.yaml", content_type : "application/x-yaml", empty : false },
    { name : "kubeconfig.yaml", content_type : "application/x-yaml", empty : true },
    { name : "associate-eip.sh", content_type : "text/plain", empty : false },
    { name : "install-etcd.sh", content_type : "text/plain", empty : false },
    { name : "register-private.sh", content_type : "text/plain", empty : false },
    { name : "register-targetgroups.sh", content_type : "text/plain", empty : false },
    { name : "setup-seed.sh", content_type : "text/plain", empty : false },
    { name : "setup-server.sh", content_type : "text/plain", empty : false },
    { name : "setup-agent.sh", content_type : "text/plain", empty : false },
    { name : "ebs-csi-driver.yaml", content_type : "application/x-yaml", empty : false },
  ]

  # Control plane node configurations
  add_server_taint       = var.add_server_taint
  disabled_server_charts = var.disabled_server_charts

  replacements = {
    token : local.token
    server : local.server_fqdn
    tls_san : local.tls_san
    bucket_name : local.bucket_id
    bucket_region : local.bucket_region
    server_taint : local.add_server_taint
    disabled_server_charts : local.disabled_server_charts

    rke2_version : local.rke2_version
    api_endpoint : local.api_endpoint
    eip_allocation_id : local.cloud_config.eip_allocation_id
    zone_id : local.cloud_config.zone_id
    api_tg_arn : local.cloud_config.api_tg_arn
    in_api_tg_arn : local.cloud_config.in_api_tg_arn
    in_srv_tg_arn : local.cloud_config.in_srv_tg_arn

    aws_ebs_csi_driver : local.addon_config.aws_ebs_csi_driver
  }
}
