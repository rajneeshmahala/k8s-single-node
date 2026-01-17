# 🐳 Single Node Kubernetes Cluster on Raspberry Pi 5  
Using **kubeadm + containerd + Flannel + MetalLB (Single IP LoadBalancer)**

This project installs a complete **single-node Kubernetes cluster** on:
- Raspberry Pi 5  
- Ubuntu Server 24.04  
- kubeadm  
- MetalLB with **ONE static IP** for all LoadBalancer services  

Perfect for:
- Home lab
- Edge computing
- Bare-metal Kubernetes learning
- IoT + DevOps practice

---

## 🔧 Requirements

| Item              | Value Example            |
|-------------------|--------------------------|
| OS                | Ubuntu Server 24.04      |
| Node IP           | `192.168.31.105`         |
| LoadBalancer IP   | `192.168.31.240` (Free)  |
| Kubernetes        | v1.29.x                  |
| Architecture      | ARM64 (RPi5)             |

Ensure:
- Your Raspberry Pi has internet
- Your LoadBalancer IP is **unused** in LAN

---

## 🚀 Quick Install

1. Edit script values:
```bash
nano k8s-single-node.sh



Script will:
	•	Disable swap
	•	Install containerd
	•	Install Kubernetes
	•	Initialize cluster
	•	Install Flannel
	•	Install MetalLB
	•	Assign single LoadBalancer IP

##################################change the value acc to req ################################################

NODE_IP="192.168.31.105"
LB_IP="192.168.31.240"
