#!/bin/bash
# Handle stale mirrors
sudo yum clean all
sudo yum makecache

sudo yum update -y
sudo yum install wget jq ruby amazon-efs-utils -y

CURRENT_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

# Install CodeDeploy
cd /home/ec2-user
wget https://aws-codedeploy-$CURRENT_REGION.s3.$CURRENT_REGION.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Mount EFS
mkdir /mnt/efs
efs_id="${efs_id}"
mount -t efs $efs_id:/ /mnt/efs
echo $efs_id:/ /mnt/efs efs defaults,_netdev 0 0 >> /etc/fstab
