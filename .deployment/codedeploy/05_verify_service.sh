#!/bin/bash
# this script is triggered by the CodeDeploy agent (configured in the appspec.yaml)

# source common variables and functions shared by all scripts
source $(dirname $0)/common.sh


echo "rs.status()" | mongo