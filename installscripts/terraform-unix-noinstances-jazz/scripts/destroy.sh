#!/bin/bash
date

currentDir=`pwd`

echo " ======================================================="
echo " The following Stack has been marked for deletion in AWS"
echo " ________________________________________________"
cd installscripts/terraform-unix-noinstances-jazz
terraform state list

echo " ======================================================="

echo " Destroying of stack Initiated!!! "
echo " Execute  'tail -f stack_deletion.out' in below directory to see the stack deletion progress"
echo $currentDir

echo " ======================================================="

nohup terraform destroy --force >>../../stack_deletion.out &&
cd $currentDir
shopt -s extglob
sudo rm -rf !(*.out)
sudo rm -rf ../rhel7Installer.sh ../atlassian-cli* 
date
