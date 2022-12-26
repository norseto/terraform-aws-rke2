#!/bin/bash

if [ $# -lt 1 ] ; then
    echo "Usage $0 EIP_ALLOCATION_ID" 1>&2
    exit 1
fi

EIPALLOCATION_ID=$1

MY_INSTANCE=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ASTAT=1
while [ $ASTAT -ne 0 ] ; do
  aws ec2 associate-address --allocation-id $EIPALLOCATION_ID --instance $MY_INSTANCE --region $REGION; ASTAT=$?
  if [ $ASTAT -ne 0 ] ; then
    sleep 1
  fi
done
