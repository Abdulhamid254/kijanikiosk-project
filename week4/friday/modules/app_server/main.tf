variable "node_role" { type = string }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "zone_region" { type = string }

resource "null_resource" "app_node" {
  triggers = {
    node_role   = var.node_role
    hostname    = "kijanikiosk-${var.node_role}"
  }
  provisioner "local-exec" {
    command = "echo 'Provisioned node: kijanikiosk-${var.node_role}'"
  }
}

output "computed_hostname" {
  value = "kijanikiosk-${var.node_role}"
}
