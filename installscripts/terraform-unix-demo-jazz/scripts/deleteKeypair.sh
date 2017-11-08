#!/bin/bash

KEY_NAME=$1

aws ec2 delete-key-pair --key-name $KEY_NAME

