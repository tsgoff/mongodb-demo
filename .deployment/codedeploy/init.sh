#!/bin/bash

source $(dirname $0)/common.sh

ADMINPW=`aws ssm get-parameters --with-decryption --names "/${PROJECT}/${APP}/${PUPPET_ENVIRONMENT}/adminpw" --output text --query "Parameters[*].{Value:Value}"`

systemctl stop mongod
mkdir -p /data/db/mongodb
mongod --port 27017 --dbpath /data/db/mongodb &
sleep 5
echo 'use admin;
db.createUser(
 {
  user: "admin",
  pwd: "'$ADMINPW'",
  roles: [ { role: "root", db: "admin"} ]
 }
);' > /root/mongoinit
mongo < /root/mongoinit && rm -f /root/mongoinit
sleep 5
pkill mongod
sleep 5
chown -R mongodb:mongodb /data/db/mongodb && systemctl restart mongod && systemctl status mongod

touch /data/init.lock

puppet apply --environment "${PUPPET_ENVIRONMENT}" \
    --modulepath ${PUPPETBASEDIR}/modules/:${PUPPETBASEDIR}/external-modules/ \
    ${PUPPETBASEDIR}/manifests/site.pp  \
    --logdest syslog

puppet apply --environment "${PUPPET_ENVIRONMENT}" \
    --modulepath ${PUPPETBASEDIR}/modules/:${PUPPETBASEDIR}/external-modules/ \
    ${PUPPETBASEDIR}/manifests/site.pp  \
    --logdest syslog
