#!/bin/bash

ETCD_VER=v3.5.7
GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=$${GOOGLE_URL}
rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
curl -L $${DOWNLOAD_URL}/$${ETCD_VER}/etcd-$${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1

cp /tmp/etcd-download-test/etcd /usr/local/bin
cp /tmp/etcd-download-test/etcdctl /usr/local/bin
cp /tmp/etcd-download-test/etcdutl /usr/local/bin
chmod +x /usr/local/bin/etcd /usr/local/bin/etcdctl /usr/local/bin/etcdutl

rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
