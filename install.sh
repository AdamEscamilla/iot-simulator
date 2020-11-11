#!/bin/bash
set -eu

[ `id -u -n` == "root" ] && \
  { printf "%s\n" "must be non-root user" && exit 1 ; }

sudo dd if=/dev/zero of=/swapfile bs=128M count=8
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab

. /etc/os-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

case "$VERSION_ID" in
    "16.04")
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update -y && \
          apt-cache policy docker-ce && \
          sudo apt-get install -y docker-ce
        ;;
    "18.04")
        sudo apt-get update -y && \
          sudo apt install -y docker.io
esac

sudo systemctl enable  docker
sudo systemctl start  docker
sudo systemctl status --no-pager docker
