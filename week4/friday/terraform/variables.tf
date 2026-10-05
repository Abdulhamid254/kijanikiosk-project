variable "target_region" {
  type    = string
  default = "local-multipass"
}
variable "server_instance_type" {
  type    = string
  default = "m1.small"
}
variable "ssh_key_identifier" {
  type    = string
  default = "id_rsa"
}
variable "server_roles" {
  type    = set(string)
  default = ["api", "payments", "logs"]
}
