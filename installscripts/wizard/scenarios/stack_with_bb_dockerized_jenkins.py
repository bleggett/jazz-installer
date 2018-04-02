#!/usr/bin/python
import os
import sys
import subprocess
from support.jazz_common import INSTALL_SCRIPT_FOLDER, REPO_ROOT, TERRAFORM_FOLDER_PATH, parse_and_replace_parameter_list
from support.jazz_jenkins import get_and_add_docker_jenkins_config
from support.jazz_bitbucket import get_and_add_existing_bitbucket_config

# Global variables


def pause():
    programPause = raw_input("Press the <ENTER> key to continue...")


def check_dockerised_jenkins_pem(installer_root):
    """
        Check if the jenkins dockerised has created jenkinskey.pem private keys
    """
    # Check if both files are been added to home derectory
    jenkins_pem = installer_root + "/installscripts/dockerfiles/jenkins/jenkinskey.pem"
    if not os.path.isfile(jenkins_pem):
        sys.exit("File jenkinskey.pem missing. Aborting! ")

    # Copy the pem keys and give relavant permissions to a dockerkeys Location. This is different from Scenario 1.
    subprocess.call('cp -f {0} {1}sshkeys/dockerkeys'.format(
        jenkins_pem, INSTALL_SCRIPT_FOLDER).split(' '))
    subprocess.call(
        'sudo chmod 400 {0}sshkeys/dockerkeys/jenkinskey.pem'.format(
            INSTALL_SCRIPT_FOLDER).split(' '))


def start(parameter_list):
    """
        start stack creation
    """
    parse_and_replace_parameter_list(parameter_list)

    # Get Bitbucket configuration details
    get_and_add_existing_bitbucket_config()

    # Launch the Jenkins Docker
    print("Deploying Dockerized Jenkins server==============>")
    get_and_add_docker_jenkins_config("/installscripts/dockerfiles/")
    check_dockerised_jenkins_pem()

    # All variables are set and ready to call terraform
    os.chdir(TERRAFORM_FOLDER_PATH)

    subprocess.call(
        'nohup ./scripts/create.sh >>../../stack_creation.out&', shell=True)
    subprocess.call('cp ./scripts/destroy.sh ../../'.split(' '))

    print(
        "\n\nPlease execute  tail -f stack_creation.out | grep 'Creation complete' in the below directory to see the stack creation progress "
    )
    print(os.path.realpath('../../'))
    print("\n\n")
