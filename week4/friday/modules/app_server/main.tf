variable "node_role" { type = string }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "zone_region" { type = string }

# Local variables to track and compute node metrics dynamically
locals {
  vm_identifier = "kijanikiosk-${var.node_role}"
  domain_suffix = ".local"
}

# Platform-agnostic tracking component ensuring dynamic node specifications are managed as code
resource "null_resource" "app_node" {
  triggers = {
    node_role     = var.node_role
    instance_type = var.instance_type
    key_name      = var.key_name
    zone_region   = var.zone_region
    full_hostname = "${local.vm_identifier}${local.domain_suffix}"
  }

  provisioner "local-exec" {
    command = "echo 'Initializing operational validation context for architecture target: ${local.vm_identifier}'"
  }
}

# Export the dynamic tracking values to the parent context
output "computed_hostname" {
  value = local.vm_identifier
}
