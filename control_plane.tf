resource "null_resource" "control_plane_setup" {
  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.control_plane_ip
  }

  provisioner "remote-exec" {
    inline = [
      # 1. Preparar el sistema 
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      
      # 2. Instalar dependencias básicas y Containerd
      "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg containerd",
      
      # 3. Instalar Kubeadm, Kubelet y Kubectl
      "sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",

      # 4. Inicializar Cluster
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      
      # 5. Instalar Red Flannel
      "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"
    ]
  }

  # Extraer el comando de unión usando sshpass (requiere que lo tengas instalado localmente)
  provisioner "local-exec" {
    command = "sshpass -p '${var.ssh_password}' ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${var.control_plane_ip} 'kubeadm token create --print-join-command' > join_command.sh"
  }
}