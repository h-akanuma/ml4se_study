#!/bin/bash

cat <<'EOF' > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

yum -y update
yum install -y git
yum install -y openssl-devel readline-devel zlib-devel
yum install -y vlgothic-*
yum install -y google-chrome-stable
