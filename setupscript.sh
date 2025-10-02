#!/bin/bash
#
## --- PART 1: INSTALL CONTAINER RUNTIME (containerd) ---
echo "[TASK 1] Installing containerd........"
sudo apt-get update
sudo apt-get install -y containerd
#
## Create the default configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
#
## Configure containerd to use the systemd cgroup driver, which is required by the kubelet
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
#
## Restart containerd to apply the change
sudo systemctl restart containerd
sudo systemctl enable containerd
#
## --- PART 2: DISABLE SWAP ---
echo "[TASK 2] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
#
## --- PART 3: CONFIGURE KERNEL PARAMETERS ---
echo "[TASK 3] Configuring kernel parameters for Kubernetes networking..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
#
sudo modprobe overlay
sudo modprobe br_netfilter
#
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
#
sudo sysctl --system
#
## --- PART 4: INSTALL KUBERNETES COMPONENTS (kubeadm, kubelet, kubectl) ---
echo "[TASK 4] Installing kubeadm, kubelet, and kubectl..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
#
## Download the public signing key
apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
#
## Add the Kubernetes apt repository
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
 # sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
# Add the latest k8s reposotory to the sources list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

#
## Install the components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
#
## Pin the versions to prevent accidental upgrades
sudo apt-mark hold kubelet kubeadm kubectl
#
echo "✅ All prerequisites are installed and configured."
