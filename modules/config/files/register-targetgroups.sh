#!/bin/bash

# LIFEC=$(curl -s -X GET "http://169.254.169.254/latest/meta-data/instance-life-cycle")
# if [ "x$LIFEC" = "xspot" ] ; then
#   exit 0
# fi

if [ $# -lt 1 ] ; then
  echo "Usage $0 [TARGET_GROUP_ARN] [PORT] " 1>&2
  exit 1
fi

TG=$1
PORT=$2
MY_INSTANCE=$(ec2metadata --instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

ASTAT=1
while [ $ASTAT -ne 0 ] ; do
  aws elbv2 register-targets --target-group-arn "$TG" --targets Id="$MY_INSTANCE",Port="$PORT" --region $REGION; ASTAT=$?
  if [ $ASTAT -ne 0 ] ; then
    sleep 1
  fi
done
