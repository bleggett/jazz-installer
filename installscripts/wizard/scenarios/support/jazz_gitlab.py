#!/usr/bin/python
import os
import subprocess
import urllib2

from jazz_common import replace_tfvars, getJazzRoot, TERRAFORM_FOLDER_PATH


def add_gitlab_config_to_files(parameter_list):
    """
    Add gitlab configuration to terraform.tfvars
    parameter_list = [  gitlab_public_ip ,
                        gitlab_username,
                        gitlab_passwd ]
    """
    print("Adding Gitlab config to Terraform variables")
    tfvars_file = getJazzRoot() + TERRAFORM_FOLDER_PATH + "terraform.tfvars"
    replace_tfvars('scm_publicip', parameter_list[0], tfvars_file)
    replace_tfvars('scm_username', parameter_list[1], tfvars_file)
    replace_tfvars('scm_passwd', parameter_list[2], tfvars_file)
    replace_tfvars('scm_type', 'gitlab', tfvars_file)
    replace_tfvars('scm_pathext', '/', tfvars_file)


def get_and_add_docker_gitlab_config(gitlab_docker_path):
    """
        Launch a Dockerized Gitlab server.
    """
    os.chdir(getJazzRoot() + TERRAFORM_FOLDER_PATH + "dockerfiles/gitlab/")
    print("Running docker launch script  for gitlab")
    subprocess.call([
        'sh', 'launch_gitlab_docker.sh', '|', 'tee', '-a',
        '../../gitlab_creation.out'
    ])
    print("Gitlab container launched")

    # Get values to create the array
    parameter_list = []
    with open("docker_gitlab_vars") as f:
        for line in f:
            parameter_list.append(line.rstrip())

    print(parameter_list[0:])

    add_gitlab_config_to_files(parameter_list)
