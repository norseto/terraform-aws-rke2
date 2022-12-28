locals {
  bucket_id     = var.bucket_id
  bucket_region = var.bucket_region
  token         = var.token
  server_fqdn   = var.server_fqdn
  tls_san       = compact(concat(var.tls_san, [var.server_fqdn]))
  versioning    = var.versioning
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
  }
}
