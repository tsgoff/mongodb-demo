# MongoDB 

MonngoDB 5.0 Demo on AWS Graviton EC2 instances with GP3 volumes. Deployed with local Puppet apply over CodeDeploy.

Default is 1x c7g.medium. This can be adjusted in ./terraform/env/int/main.tf (instance_count must be odd and max 50)

**Show cluster state:**

    ssh demo@`aws ec2 describe-instances --filters \
      "Name=tag:Name,Values=*mongodb-01*"  \
      "Name=instance-state-name,Values=running" --query \
      "Reservations[*].Instances[*].PublicIpAddress" --output text` \
      "echo 'rs.status()' | mongo"



## Inputs

| Variables |
|------|
| AWS_DEFAULT_REGION |
| AWS_ROLE_ARN **or** AWS_ACCESS_KEY_ID |
| AWS_EXTERNAL_ID **or** AWS_SECRET_ACCESS_KEY |
| PUBLIC_KEY |
