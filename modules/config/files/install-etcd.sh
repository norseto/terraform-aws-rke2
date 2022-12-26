#!/bin/bash

ETCD_VER=v3.4.13
GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=$${GOOGLE_URL}
rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
curl -L $${DOWNLOAD_URL}/$${ETCD_VER}/etcd-$${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
