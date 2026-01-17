resource "null_resource" "worker_setup" {
  count = length(var.worker_ips)
  depends_on = [null_resource.control_plane_setup]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.worker_ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab",
      "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl containerd",
      "sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm",
      "sudo apt-mark hold kubelet kubeadm"
    ]
  }

  # Enviar el script de unión
  provisioner "file" {
    source      = "join_command.sh"
    destination = "/tmp/join_command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /tmp/join_command.sh"
    ]
  }
}