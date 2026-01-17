variable "ssh_user" {
  default = "eracles" 
}

variable "ssh_password" {
  default   = "eracles"
  sensitive = true 
}

variable "control_plane_ip" {
  default = "192.168.1.122"
}

variable "worker_ips" {
  type    = list(string)
  default = ["192.168.1.121", "192.168.1.123"]
}