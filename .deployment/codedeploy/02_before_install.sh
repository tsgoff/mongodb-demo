#!/bin/bash
# this script is triggered by the CodeDeploy agent (configured in the appspec.yaml)

# source common variables and functions shared by all scripts
source $(dirname $0)/common.sh

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

mkdir -p /data/deploy
#mkdir -p /data/mongodb

#dummy dir for puppet
mkdir -p /etc/puppet/code/environments/${PUPPET_ENVIRONMENT}

