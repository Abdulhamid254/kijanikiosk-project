output "provisioned_node_details" {
  value = {
    for role, node in module.infrastructure_nodes : role => {
      role_identifier = role
      target_hostname = node.computed_hostname
    }
  }
}
