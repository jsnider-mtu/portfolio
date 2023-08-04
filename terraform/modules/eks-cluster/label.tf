module "eks_cluster_label" {
  source      = "cloudposse/label/null"
  namespace   = "jsnider-mtu"
  environment = var.env
  name        = var.name
}
