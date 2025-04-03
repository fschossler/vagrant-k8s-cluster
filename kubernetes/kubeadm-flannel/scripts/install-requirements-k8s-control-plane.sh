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
export DEBIAN_FRONTEND=noninteractive
sudo apt -qq install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt -qq update
sudo apt-get -qq install containerd.io -y
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
cat >>/etc/hosts<<EOF
192.168.56.50 k8s-control-plane.example.com k8s-control-plane
192.168.56.51 node1.example.com node1
192.168.56.52 node2.example.com node2
EOF

echo "======================================================================"
echo "Start K8s Control Plane"
echo "======================================================================"
kubeadm init --apiserver-advertise-address=192.168.56.50 --pod-network-cidr=10.244.0.0/16

echo "======================================================================"
echo "Enable others users to use kubectl commands"
echo "======================================================================"
mkdir -p -v /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -v -R vagrant:vagrant /home/vagrant/.kube/
export KUBECONFIG=/home/vagrant/.kube/config

echo "======================================================================"
echo "Install pod-network addon (Flannel)"
echo "======================================================================"
sudo --user=vagrant kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "======================================================================"
echo "Install autocomplete kubectl and use an alias"
echo "======================================================================"
sudo apt-get -qq install bash-completion
echo 'alias k=kubectl' >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo "source <(kubectl completion bash | sed 's/kubectl/k/g' )" >> /home/vagrant/.bashrc
bash

echo "======================================================================"
echo "Untaint control plane"
echo "======================================================================"
sudo --user=vagrant kubectl taint nodes k8s-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

echo "======================================================================"
echo "Install Metrics Server Kubernetes"
echo "======================================================================"
sudo wget -q https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sudo sed -i '/secure-port=10250/a \        - --kubelet-insecure-tls' components.yaml
sudo --user=vagrant kubectl apply -f components.yaml

echo "======================================================================"
echo "Add MetalLB to the Cluster"
echo "======================================================================"
sudo --user=vagrant kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
echo "======================================================================"
echo "Waiting MetalLB controller pod be in Running state..."
echo "======================================================================"
sudo --user=vagrant kubectl wait --namespace metallb-system --for=condition=ready pod --selector=component=controller --timeout=120s
sleep 10
cat >>/home/vagrant/metallb-configs.yml<<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: main-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.53-192.168.56.60 
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - main-pool
EOF
sudo --user=vagrant kubectl apply -f /home/vagrant/metallb-configs.yml
sudo rm /home/vagrant/metallb-configs.yml

echo "======================================================================"
echo "Taint control plane"
echo "======================================================================"
sudo sleep 10
sudo --user=vagrant kubectl taint nodes k8s-control-plane node-role.kubernetes.io/control-plane:NoSchedule

echo "======================================================================"
echo "Create a sh file with the join command"
echo "======================================================================"
kubeadm token create --print-join-command > /joincluster.sh