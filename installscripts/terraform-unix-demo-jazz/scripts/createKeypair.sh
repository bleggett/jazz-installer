#!/bin/bash

KEY_NAME=$1
PRIVATE_KEY=$2
sudo rm -rf $PRIVATE_KEY
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $PRIVATE_KEY
sudo chmod 400 $PRIVATE_KEY
