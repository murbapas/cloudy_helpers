#!/bin/bash

# Prerequisites #
#################

# I assume:
# - You have access to a VM based on a current ubuntu cloud image
# - You have sudo rights on this VM
# - Your user is 'ubuntu'
# - Your home dir is '/home/ubuntu'
 
# If you fulfill these requirements you can spin up a three node kind cluster
# by executing this script on your VM like this:

# curl -s https://raw.githubusercontent.com/murbapas/cloudy_helpers/refs/heads/main/setup_3_node_kind_on_ubu_cloud.sh | bash

# !!!this is meant for lab environments!!!
# !!!no security!!!


# prepare the system #
######################

# create /home/ubuntu/bin directory and add it to $PATH
if [ ! -d ~/bin ]; then
	mkdir ~/bin
fi
echo "export PATH=$PATH:/home/ubuntu/bin" >> ~/.bashrc

source ~/.bashrc

# Allow unprivileeged users to bind ports >0
echo "net.ipv4.ip_unprivileged_port_start=0" | sudo tee /etc/sysctl.d/50-unprivileged-ports.conf
sudo sysctl --system

# install rootless docker #
###########################

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# make docker rootless
sudo apt install -y uidmap docker-ce-rootless-extras

sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock

dockerd-rootless-setuptool.sh install

echo "export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock" >> ~/.bashrc
source ~/.bashrc

# install kind #
################

curl -Lo ~/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ~/bin/kind

cat << EOF > /tmp/kind-three-node-cluster.yaml
# three node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 32000
    hostPort: 32000
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 32100
    hostPort: 32100
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30000
    hostPort: 30000
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30055
    hostPort: 30055
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30056
    hostPort: 30056
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30100
    hostPort: 30100
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30200
    hostPort: 30200
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30300
    hostPort: 30300
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30400
    hostPort: 30400
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30500
    hostPort: 30500
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30600
    hostPort: 30600
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30700
    hostPort: 30700
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 30800
    hostPort: 30800
    listenAddress: "0.0.0.0"
    protocol: tcp
- role: worker
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 8000
    hostPort: 8000
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 8080
    hostPort: 8001
    listenAddress: "0.0.0.0"
    protocol: tcp

- role: worker
EOF

~/bin/kind create cluster --config /tmp/kind-three-node-cluster.yaml

# install kubectl and autocompletion #
######################################

# get the kubectl binary
curl -Lo ~/bin/kubectl  "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ~/bin/kubectl

~/bin/kubectl completion bash >> ~/.bash_kube_completion
echo "source ~/.bash_kube_completion" >> ~/.bashrc

mkdir ~/.bash_completion.d
curl https://raw.githubusercontent.com/cykerway/complete-alias/master/complete_alias \
     > ~/.bash_completion.d/complete_alias

cat << EOF >> ~/.bashrc
source ~/.bash_completion.d/complete_alias
alias k="kubectl $@"
complete -F _complete_alias k
EOF

source ~/.bashrc

# install kubectx for convenience
sudo apt install kubectx
