#!/bin/true
#
# This is not an executable script, just a set of names and variable declarations.
#
# Use it with:
#   source common.sh

BASEPATH="/data/deploy"
PUPPETBASEDIR=${BASEPATH}/puppet

PUPPET_ENVIRONMENT=`/bin/cat /etc/puppet_env`
APP=`/bin/cat /etc/puppet_app`
PROJECT=`/bin/cat /etc/puppet_project`

export FACTER_app=$APP

#export replicaset name
export FACTER_replicaset="$APP.$PUPPET_ENVIRONMENT"

function get-ec2-ips {
aws ec2 describe-instances --filters "Name=tag:App,Values=${APP}" \
    "Name=instance-state-name,Values=running" \
    "Name=tag:Environment,Values=${PUPPET_ENVIRONMENT}" \
    --query 'Reservations[*].Instances[*].[LaunchTime,InstanceId,PrivateIpAddress,Tags[?Key==`Name`] | [0].Value]| sort_by(@, &@[0][3])' | \
    grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"
}