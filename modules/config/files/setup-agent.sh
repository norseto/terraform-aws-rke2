#!/usr/bin/env bash

curl -sfL https://get.rke2.io | ${rke2_version} INSTALL_RKE2_TYPE="agent" sh -
mkdir -p /etc/rancher/rke2/config.yaml.d
ln -s /var/lib/rancher/rke2/bin/kubectl /usr/bin

aws s3 cp s3://${bucket_name}/config/agent.yaml /etc/rancher/rke2/config.yaml

printf "node-label+:\n- node.kubernetes.io/instance-id=%s\n" "$(ec2metadata --instance-id)" > /etc/rancher/rke2/config.yaml.d/10-node-label.yaml
printf "kubelet-arg+:\n- node-ip=%s" "$(ec2metadata --local-ipv4)" > /etc/rancher/rke2/config.yaml.d/99-node-ip.yaml

systemctl enable rke2-agent.service
systemctl start rke2-agent.service
