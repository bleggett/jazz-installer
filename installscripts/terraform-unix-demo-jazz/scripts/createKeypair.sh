#!/bin/bash

KEY_NAME=$1
PRIVATE_KEY=$2

aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $PRIVATE_KEY
chmod 400 $PRIVATE_KEY

