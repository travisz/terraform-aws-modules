#!/bin/bash
# Handle stale mirrors
sudo yum clean all
sudo yum makecache

sudo yum update -y
