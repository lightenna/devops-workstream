#!/bin/bash
# Find non-marketplace images owned by CentOS
aws --region eu-west-2 ec2 describe-images --owners "410186602215" --filters "Name=name,Values=CentOS Linux 7 x86_64 HVM EBS*"