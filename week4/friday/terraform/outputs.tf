output "ansible_inventory_block" {
  value = join("\n", [
    for role in var.server_roles : 
    "${role} ansible_connection=local server_role=${role}"
  ])
  description = "Formatted block containing explicit node attributes ready to be appended directly into the hosts file"
}

output "ssh_verification_commands" {
  value = {
    for role in var.server_roles : 
    role => "ssh -i ~/.ssh/${var.ssh_key_identifier} ubuntu@kijanikiosk-${role}.local"
  }
  description = "Manual administrative SSH connect blocks for verification checkpoints"
}
