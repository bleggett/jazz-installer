#!/bin/bash
rm -f ./settings.txt
date
terraform apply \
          -var 'aws_access_key=$AWS_ACCESS_KEY_ID' \
          -var 'aws_secret_key=$AWS_SECRET_ACCESS_KEY' \
          -var 'region=$AWS_DEFAULT_REGION'
date
echo " ======================================================="
echo " The following stack has been created in AWS"
echo " ________________________________________________"
terraform state list
echo " ======================================================="
echo " Please use the following values for checking out Jazz"
echo " ________________________________________________"
cat ./settings.txt
echo " ======================================================="
echo " Installation complete! To cleanup Jazz stack and its resources execute ./destroy.sh in this directory."
realpath ../../
echo " ======================================================="
