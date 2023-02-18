#!/usr/bin/env bash

mkdir -p /etc/rancher/rke2/config.yaml.d

EIPALLOCATION_ID="${eip_allocation_id}"
if [ ! -z "$EIPALLOCATION_ID" ] ; then
  aws s3 cp s3://${bucket_name}/config/associate-eip.sh /etc/rancher/rke2/
  aws s3 cp s3://${bucket_name}/config/register-private.sh /etc/rancher/rke2/
  bash /etc/rancher/rke2/register-private.sh ${zone_id}
  bash /etc/rancher/rke2/associate-eip.sh "$EIPALLOCATION_ID"
fi

API_TGARN="${api_tg_arn}"
IN_API_TGARN="${in_api_tg_arn}"
IN_SRV_TGARN="${in_srv_tg_arn}"
if [ ! -z "$API_TGARN" -a ! -z "$IN_API_TGARN" -a ! -z "$IN_SRV_TGARN" ] ; then
  aws s3 cp s3://${bucket_name}/config/register-targetgroups.sh /etc/rancher/rke2/
  bash /etc/rancher/rke2/register-targetgroups.sh $API_TGARN 6443
  bash /etc/rancher/rke2/register-targetgroups.sh $IN_API_TGARN 6443
  bash /etc/rancher/rke2/register-targetgroups.sh $IN_SRV_TGARN 9345
fi

while :; do
  curl -sfL https://get.rke2.io | ${rke2_version} sh -
  if [ -f /usr/local/lib/systemd/system/rke2-server.service ] ; then break; fi
done
ln -s /var/lib/rancher/rke2/bin/kubectl /usr/bin

aws s3 cp s3://${bucket_name}/config/install-etcd.sh /etc/rancher/rke2/
bash /etc/rancher/rke2/install-etcd.sh

aws s3 cp s3://${bucket_name}/config/control-plane-init.yaml /etc/rancher/rke2/
aws s3 cp s3://${bucket_name}/config/control-plane.yaml /etc/rancher/rke2/

# curl -s --insecure --connect-timeout 5 https://${server}:9345/cacerts>/dev/null; FIRST=$?
# if [ $FIRST -ne 0 ] ; then
  cp /etc/rancher/rke2/control-plane-init.yaml /etc/rancher/rke2/config.yaml
# else
#   cp /etc/rancher/rke2/control-plane.yaml /etc/rancher/rke2/config.yaml
# fi

printf "node-label+:\n- node.kubernetes.io/instance-id=%s\n" "$(ec2metadata --instance-id)" > /etc/rancher/rke2/config.yaml.d/10-node-label.yaml
printf "kubelet-arg+:\n- node-ip=%s" "$(ec2metadata --local-ipv4)" > /etc/rancher/rke2/config.yaml.d/99-node-ip.yaml

if [ "none" != "${aws_ebs_csi_driver}" ] ; then
  mkdir -p /var/lib/rancher/rke2/server/manifests
  aws s3 cp s3://${bucket_name}/config/ebs-csi-driver.yaml /var/lib/rancher/rke2/server/manifests
fi

systemctl enable rke2-server.service
systemctl start rke2-server.service

# if [ $FIRST -ne 0 ] ; then
  grep 127.0.0.1 /etc/rancher/rke2/rke2.yaml >/dev/null; STARTED=$?
  while [ $STARTED -ne 0 ]
  do
    sleep 3
    grep 127.0.0.1 /etc/rancher/rke2/rke2.yaml >/dev/null; STARTED=$?
  done
  sed -e 's/127.0.0.1/${api_endpoint}/g' /etc/rancher/rke2/rke2.yaml > /etc/rancher/rke2/rke2_fqdn.yaml
  aws s3 cp /etc/rancher/rke2/rke2_fqdn.yaml s3://${bucket_name}/config/kubeconfig.yaml
# fi
