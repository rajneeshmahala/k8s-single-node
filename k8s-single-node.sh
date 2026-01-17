#!/bin/bash
set -e

# ===============================
# CONFIG
# ===============================
NODE_IP="192.168.31.105"
LB_IP="192.168.31.240"
K8S_VERSION="1.29"

echo "Starting Kubernetes Single Node Install..."

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Kernel settings
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

# Stop auto upgrades
systemctl stop unattended-upgrades apt-daily apt-daily-upgrade || true
systemctl disable unattended-upgrades apt-daily apt-daily-upgrade || true

# Install containerd
apt update
apt install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Kubernetes packages
apt install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key |
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" \
> /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Initialize cluster
kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--apiserver-advertise-address=${NODE_IP}

# kubectl setup
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Allow pods on control-plane
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

sleep 15

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: single-ip
  namespace: metallb-system
spec:
  addresses:
  - ${LB_IP}/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2
  namespace: metallb-system
EOF

echo ""
echo "Kubernetes Single Node Cluster Ready!"
echo "LoadBalancer IP: $LB_IP"
