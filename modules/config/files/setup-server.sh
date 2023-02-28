#!/usr/bin/env bash

STARTUP=$1
OSTYPE=$2

mkdir -p /etc/rancher/rke2/config.yaml.d
mkdir -p /var/lib/rancher/rke2/server/manifests

while :; do
  curl -sfL https://get.rke2.io | ${rke2_version} sh -
  if [ -f /usr/local/lib/systemd/system/rke2-server.service ] ; then break; fi
done
ln -s /var/lib/rancher/rke2/bin/kubectl /usr/bin

API_TGARN="${api_tg_arn}"
IN_API_TGARN="${in_api_tg_arn}"
IN_SRV_TGARN="${in_srv_tg_arn}"
if [ ! -z "$API_TGARN" -a ! -z "$IN_API_TGARN" ! -z "$IN_SRV_TGARN" ] ; then
  aws s3 cp s3://${bucket_name}/config/register-targetgroups.sh /etc/rancher/rke2/
  bash /etc/rancher/rke2/register-targetgroups.sh $API_TGARN 6443
  bash /etc/rancher/rke2/register-targetgroups.sh $IN_API_TGARN 6443
  bash /etc/rancher/rke2/register-targetgroups.sh $IN_SRV_TGARN 9345
fi

aws s3 cp s3://${bucket_name}/config/install-etcd.sh /etc/rancher/rke2/
bash /etc/rancher/rke2/install-etcd.sh

aws s3 cp s3://${bucket_name}/config/control-plane.yaml /etc/rancher/rke2/
cp /etc/rancher/rke2/control-plane.yaml /etc/rancher/rke2/config.yaml

printf "node-label+:\n- node.kubernetes.io/instance-id=%s\n" "$(ec2metadata --instance-id)" > /etc/rancher/rke2/config.yaml.d/10-node-label.yaml
printf "kubelet-arg+:\n- node-ip=%s" "$(ec2metadata --local-ipv4)\n" > /etc/rancher/rke2/config.yaml.d/99-node-ip.yaml

if [ "$STARTUP" = "true" ] ; then
  systemctl enable rke2-server.service
  systemctl start rke2-server.service
fi
