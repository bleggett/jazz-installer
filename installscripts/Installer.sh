#!/bin/sh
#
# File: Installer.sh
# Description: Installs the Jazz serverless framework from Centos7 ec2-instance.
#
# ---------------------------------------------
# Usage:
# ---------------------------------------------
# To Installer, run:
# ./Installer -b branch_name
# ---------------------------------------------

# Variables section

# URLS
INSTALLER_GITHUB_URL="https://github.com/tmobile/jazz-installer.git"

# Installation directory
INSTALL_DIR=`pwd`
REPO_PATH=$INSTALL_DIR/jazz-installer

# Log file to record the installation logs
JAZZ_BRANCH=""

function install_packages () {

  # Create a temporary folder .
  # Here we will have all the temporary files needed and delete it at the end
  rm -rf $INSTALL_DIR/jazz_tmp
  mkdir $INSTALL_DIR/jazz_tmp

  #Get Jazz Installer code base
  rm -rf jazz-installer
  git clone -b $JAZZ_BRANCH $INSTALLER_GITHUB_URL

}

function post_installation () {
  # Move the software install log jazz Installer
  mv $LOG_FILE $REPO_PATH

  # Set the permissions
  chmod -R +x $REPO_PATH/installscripts/*
  mkdir -p $REPO_PATH/installscripts/sshkeys/dockerkeys

  # Call the python script to continue installation process
  cd $REPO_PATH/installscripts/wizard
  #sed -i "s|\"jazz_install_dir\".*$|\"jazz_install_dir\": \"$INSTALL_DIR\"|g" config.py
  python ./run.py $JAZZ_BRANCH $INSTALL_DIR

  # Clean up the jazz_tmp folder
  rm -rf $INSTALL_DIR/jazz_tmp
}

JAZZ_BRANCH="$1"

install_packages && post_installation
