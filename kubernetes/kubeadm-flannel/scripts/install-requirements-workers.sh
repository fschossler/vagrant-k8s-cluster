#!/bin/bash
echo "======================================================================"
echo "Turn off Swap"
echo "======================================================================"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "======================================================================"
echo "Iptables rule recommended by K8s"
echo "======================================================================"
lsmod | grep br_netfilter
sudo modprobe br_netfilter
sudo modprobe overlay
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

echo "======================================================================"
echo "Containerd installation"
echo "======================================================================"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo apt -qq install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install containerd.io -y
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup\s=\sfalse/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "======================================================================"
echo "Download and install kubectl, kubelet and kubeadm"
echo "======================================================================"
sudo apt-get -qq update && sudo apt-get -qq install -y apt-transport-https ca-certificates curl gpg
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get -qq update && sudo apt-get -qq install -y kubelet kubeadm kubectl
systemctl daemon-reload
systemctl restart kubelet

echo "======================================================================"
echo "Update hosts file"
echo "======================================================================"
sudo cat >>/etc/hosts<<EOF
192.168.56.50 k8s-control-plane.example.com k8s-control-plane
192.168.56.51 node1.example.com node1
192.168.56.52 node2.example.com node2
EOF

echo "======================================================================"
echo "Execute the script for join the cluster"
echo "======================================================================"
sudo apt-get -qq install sshpass
sshpass -p "vagrant" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@192.168.56.50:/joincluster.sh /joincluster.sh
bash /joincluster.sh