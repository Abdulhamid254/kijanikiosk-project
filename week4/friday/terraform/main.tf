module "infrastructure_nodes" {
  source   = "./modules/app_server"
  for_each = var.server_roles

  node_role     = each.key
  instance_type = var.server_instance_type
  key_name      = var.ssh_key_identifier
  zone_region   = var.target_region
}
