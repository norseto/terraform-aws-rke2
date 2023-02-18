#!/bin/bash

if [ $# -lt 1 ] ; then
    echo "Usage $0 ZONE_ID" 1>&2
    exit 1
fi

ZONE_ID="$1"
REG_TEMP_FILE=/tmp/reg_template.json
REG_FILE=/tmp/reg.json
LOCAL_IP=$(ec2metadata --local-ipv4)
cat <<_EOF > $REG_TEMP_FILE
{
  "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "SERVER_FQDN", "Type": "A", "TTL": 120,
        "ResourceRecords": [ { "Value": "LOCAL_IP_ADDRESS" } ]
      }
  }]
}
_EOF
sed -e "s/SERVER_FQDN/${server}/" -e "s/LOCAL_IP_ADDRESS/$LOCAL_IP/" $REG_TEMP_FILE > $REG_FILE
ASTAT=1
while [ $ASTAT -ne 0 ] ; do
  aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://$REG_FILE; ASTAT=$?
  if [ $ASTAT -ne 0 ] ; then
    sleep 1
  fi
done
