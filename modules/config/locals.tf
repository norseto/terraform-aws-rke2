locals {
  cluster_name = var.cluster_name
  bucket_id    = var.bucket_id
  region       = var.region
  token        = var.token
  server_fqdn  = var.server_fqdn
  tls_san      = compact(concat(var.tls_san, [var.server_fqdn]))
  rke2_version = var.rke2_version
  api_endpoint = var.api_endpoint
  versioning   = var.versioning
  cloud_config = var.cloud_config
  addon_config = var.addon_config
  tags         = var.tags

  configs = [
    { name : "control-plane.yaml", content_type : "application/x-yaml", empty : false },
    { name : "control-plane-init.yaml", content_type : "application/x-yaml", empty : false },
    { name : "agent.yaml", content_type : "application/x-yaml", empty : false },
    { name : "kubeconfig.yaml", content_type : "application/x-yaml", empty : true },
    { name : "associate-eip.sh", content_type : "text/x-sh", empty : false },
    { name : "install-etcd.sh", content_type : "text/x-sh", empty : false },
    { name : "register-private.sh", content_type : "text/x-sh", empty : false },
    { name : "register-targetgroups.sh", content_type : "text/x-sh", empty : false },
    { name : "setup-seed.sh", content_type : "text/x-sh", empty : false },
    { name : "setup-server.sh", content_type : "text/x-sh", empty : false },
    { name : "setup-agent.sh", content_type : "text/x-sh", empty : false },
  ]

  # Control plane node configurations
  add_server_taint       = var.add_server_taint
  disabled_server_charts = var.disabled_server_charts

  base_replacements = {
    cluster_name : local.cluster_name
    token : local.token
    server : local.server_fqdn
    tls_san : local.tls_san
    bucket_name : local.bucket_id
    region : local.region
    server_taint : local.add_server_taint
    disabled_server_charts : local.disabled_server_charts

    rke2_version : local.rke2_version
    api_endpoint : local.api_endpoint
    clouster_name : local.cluster_name
  }
  replacements = merge(local.base_replacements, local.cloud_config, local.addon_config)
}
