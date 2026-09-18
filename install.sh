#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

# Update system
sudo apt-get update -y
sudo apt-get install -y curl wget apt-transport-https gnupg lsb-release unzip

# 1. Docker
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu

# 2. SonarQube Container (Port 9000)
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# 3. Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

# 4. Java 17 & Maven
sudo apt-get install -y openjdk-17-jdk maven

# 5. AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

# 6. Kubectl & Helm
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 7. Configure Kubernetes Access
CLUSTER_NAME="main-eks-cluster"
AWS_REGION="us-east-1"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
mkdir -p /home/ubuntu/.kube
cp /root/.kube/config /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Wait until cluster worker nodes report Ready
echo "Waiting for worker nodes to become Ready..."
for i in {1..30}; do
  if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    echo "Nodes are Ready!"
    break
  fi
  sleep 10
done

# 8. Deploy Prometheus & Grafana via Helm Charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus without persistent storage on NodePort 30090
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.enabled=false \
  --set alertmanager.persistentVolume.enabled=false \
  --set server.service.type=NodePort \
  --set server.service.nodePort=30090

# Install Grafana without persistent storage on NodePort 30080
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=false \
  --set service.type=NodePort \
  --set service.nodePort=30080 \
  --set adminPassword='admin'