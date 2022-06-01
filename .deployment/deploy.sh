#!/usr/bin/env bash

ACCOUNTID=`aws sts get-caller-identity --query Account --output text`
REGION=`aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]'`

S3BUCKET="deploy-bucket-${ACCOUNTID}-${REGION}"
BUNDLENAME="deployment-$(date +%Y%m%d%H%M%S).tar.gz"
BUNDLEPATH="codedeploy/demo-mongodb-${ENVIRONMENT}/"
APP_NAME="demo-mongodb-${ENVIRONMENT}"
DG_NAME="demo-mongodb-${ENVIRONMENT}"
export AWS_DEFAULT_REGION='us-east-1'

function deploy {
  echo ${ENVIRONMENT} > ./codedeploy/env
  tar cfz ${BUNDLENAME} -C codedeploy/ .
  aws s3 cp ${BUNDLENAME} s3://${S3BUCKET}/${BUNDLEPATH}
  DEPLOYID=$(aws deploy create-deployment --file-exists-behavior OVERWRITE --region us-east-1 --application-name ${APP_NAME} --s3-location bucket=${S3BUCKET},key=${BUNDLEPATH}${BUNDLENAME},bundleType=tgz --deployment-group-name ${DG_NAME} --deployment-config-name CodeDeployDefault.OneAtATime --query 'deploymentId' | sed -e 's/^"//' -e 's/"$//')
  echo "triggered deployment"
  rm ${BUNDLENAME}
  echo "waiting for deployment ${DEPLOYID} to finish"
  aws deploy wait deployment-successful --region us-east-1 --deployment-id ${DEPLOYID}
  aws deploy get-deployment --region us-east-1 --deployment-id ${DEPLOYID}

}

function puppet-deps {
  echo -e "machine ${CI_SERVER_HOST}\nlogin gitlab-ci-token\npassword ${CI_JOB_TOKEN}" > ~/.netrc
  cat ~/.netrc
  mkdir -p ~/.ssh/ && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
  cd codedeploy/puppet
  r10k puppetfile install -v
  cd ../..
}

rsync -ah --exclude .deployment --exclude .git . .deployment/codedeploy/mongodb/
cd .deployment

puppet-deps
deploy
