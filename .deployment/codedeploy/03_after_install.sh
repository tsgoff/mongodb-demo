#!/bin/bash
# this script is triggered by the CodeDeploy agent (configured in the appspec.yaml)

# source common variables and functions shared by all scripts
source $(dirname $0)/common.sh

iplist=`get-ec2-ips`

#set hiera file
echo -e "---\nmongodb::hosts:" | tee /etc/puppet/hiera/app.yaml
echo "$iplist" | while read hosts
do
  echo -e "  - host : $hosts:27017"
  hostcount=$[$hostcount +1]
  if [ "$hostcount" -gt "5"  ] ; then
    echo "    priority : 0"
    echo "    votes    : 0"
  fi
done | \
  tee -a /etc/puppet/hiera/app.yaml

#set backup role
if [ `echo "$iplist" | wc -l` -gt "1" ]; then
  echo "more than one server - find secondary for backup"
  secondary=`echo $iplist | cut -d" " -f2`
  if [ `ip addr | grep $secondary | wc -l` -eq "1" ]; then
    echo -e "\nmongodb::backup : true" >> /etc/puppet/hiera/app.yaml
  else
    echo -e "\nmongodb::backup : false" >> /etc/puppet/hiera/app.yaml
  fi
else
  echo "single host - use primary for backup"
  echo -e "\nmongodb::backup : true" >> /etc/puppet/hiera/app.yaml
fi

#export ssm to facter
for SSM_ENV in cluster_key adminpw demopw
do
	export FACTER_${SSM_ENV}="`aws ssm get-parameters --with-decryption --names "/${PROJECT}/${APP}/${PUPPET_ENVIRONMENT}/${SSM_ENV}" --output text --query "Parameters[*].{Value:Value}"`"
done

puppet apply --environment "${PUPPET_ENVIRONMENT}" \
    --modulepath ${PUPPETBASEDIR}/modules/:${PUPPETBASEDIR}/external-modules/ \
    ${PUPPETBASEDIR}/manifests/site.pp

if [ `ip addr | grep \`get-ec2-ips | head -n 1\` | wc -l` -gt 0 ] && [ ! -f /data/init.lock ] ; then
  echo "primary"
  /data/deploy/init.sh && touch /data/init.lock
else
  echo "secondary or instance already initialized"
fi

#.mongoshrc.js
printf "db = connect('localhost/admin', 'admin', '$FACTER_adminpw');" > /root/.mongoshrc.js

#copy .mongorc.js
for USERS in demo
do
  cp /root/.mongorc.js /home/${USERS}/
  cp /root/.mongoshrc.js /home/${USERS}/
  chown -R ${USERS}:${USERS} /home/${USERS}/
done
