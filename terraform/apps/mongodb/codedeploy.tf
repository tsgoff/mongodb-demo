
resource "aws_iam_role" "instancerole" {
  name = "${local.tags.Project}-CodeDeployInstanceRole-${local.tags.App}-${local.tags.Environment}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# attach a policy to the created role
resource "aws_iam_role_policy" "codedeploy_instance_policy" {
  name = "${local.tags.Project}-${local.tags.App}-${local.tags.Environment}-CodeDeployInstancePolicy"
  role = aws_iam_role.instancerole.id

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "cloudwatch:PutMetricData"
              ],
              "Resource": [
                  "*"
              ],
              "Effect": "Allow"
          },
          {
              "Action": [
                  "ec2:DescribeTags"
              ],
              "Resource": [
                  "*"
              ],
              "Effect": "Allow"
          },
          {
              "Action": [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:DescribeLogGroups",
                  "logs:PutLogEvents",
                  "logs:DescribeLogStreams"
              ],
              "Resource": [
                  "arn:aws:logs:*:*:*"
              ],
              "Effect": "Allow",
              "Sid": "DefaultmanagedinstancepolicyCWLogs"
          },
          {
              "Action": [
                  "s3:Get*",
                  "s3:List*"
              ],
              "Resource": [
                  "arn:aws:s3:::deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/codedeploy/${local.tags.Project}-${local.tags.App}-${local.tags.Environment}/*",
                  "arn:aws:s3:::deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/codedeploy/${local.tags.Project}-${local.tags.App}-${local.tags.Environment}"
              ],
              "Effect": "Allow"
          },
          {
              "Action": [
                  "ssm:DescribeAssociation",
                  "ssm:GetDeployablePatchSnapshotForInstance",
                  "ssm:GetDocument",
                  "ssm:GetParameters",
                  "ssm:ListAssociations",
                  "ssm:ListInstanceAssociations",
                  "ssm:PutInventory",
                  "ssm:UpdateAssociationStatus",
                  "ssm:UpdateInstanceAssociationStatus",
                  "ssm:UpdateInstanceInformation"
              ],
              "Resource": [
                  "*"
              ],
              "Effect": "Allow",
              "Sid": "DefaultmanagedinstancepolicyAWSSSM"
          },
          {
              "Action": [
                  "ec2messages:AcknowledgeMessage",
                  "ec2messages:DeleteMessage",
                  "ec2messages:FailMessage",
                  "ec2messages:GetEndpoint",
                  "ec2messages:GetMessages",
                  "ec2messages:SendReply"
              ],
              "Resource": [
                  "*"
              ],
              "Effect": "Allow",
              "Sid": "DefaultmanagedinstancepolicyAWSEC2M"
          },
          {
                "Effect": "Allow",
                "Action": [
                  "s3:Get*",
                  "s3:List*"
                ],
                "Resource": [
                  "arn:aws:s3:::deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/codedeploy/${local.tags.Project}-${local.tags.App}-${local.tags.Environment}/*",
                  "arn:aws:s3:::aws-codedeploy-us-east-2/*",
                  "arn:aws:s3:::aws-codedeploy-us-east-1/*",
                  "arn:aws:s3:::aws-codedeploy-us-west-1/*",
                  "arn:aws:s3:::aws-codedeploy-us-west-2/*",
                  "arn:aws:s3:::aws-codedeploy-ca-central-1/*",
                  "arn:aws:s3:::aws-codedeploy-eu-west-1/*",
                  "arn:aws:s3:::aws-codedeploy-eu-west-2/*",
                  "arn:aws:s3:::aws-codedeploy-eu-central-1/*",
                  "arn:aws:s3:::aws-codedeploy-ap-northeast-1/*",
                  "arn:aws:s3:::aws-codedeploy-ap-northeast-2/*",
                  "arn:aws:s3:::aws-codedeploy-ap-southeast-1/*",
                  "arn:aws:s3:::aws-codedeploy-ap-southeast-2/*",
                  "arn:aws:s3:::aws-codedeploy-ap-south-1/*",
                  "arn:aws:s3:::aws-codedeploy-sa-east-1/*"
                ]
              }
      ]
  }
EOF
}

# create an instance profile linked to our instance role
resource "aws_iam_instance_profile" "default_instance_profile" {
  name = "${local.tags.Project}-${local.tags.App}-Instanceprofile-${local.tags.Environment}"
  role = aws_iam_role.instancerole.name
}

# IAM for CodeDeploy
# allow the services to handle some stuff on our behalf

# the role for codedeploy
resource "aws_iam_role" "CodeDeploy" {
  name = "${local.tags.Project}-${local.tags.App}-Codedeployassumerole-${local.tags.Environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# the policy for the codedeploy assumed role
resource "aws_iam_role_policy" "CodedeployPolicy" {
  name = "${local.tags.Project}-${local.tags.App}-Codedeploypolicy-${local.tags.Environment}"
  role = aws_iam_role.CodeDeploy.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:DeleteLifecycleHook",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLifecycleHooks",
        "autoscaling:PutLifecycleHook",
        "autoscaling:RecordLifecycleActionHeartbeat",
        "codedeploy:*",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "tag:GetTags",
        "tag:GetResources",
        "sns:Publish"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object" "base_folder" {
  bucket       = "deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  acl          = "private"
  key          = "codedeploy/${local.tags.Project}-${local.tags.App}-${local.tags.Environment}/"
  content_type = "application/x-directory"
}

resource "aws_codedeploy_app" "app" {
  name = "${local.tags.Project}-${local.tags.App}-${local.tags.Environment}"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${local.tags.Project}-${local.tags.App}-${local.tags.Environment}"
  service_role_arn       = aws_iam_role.CodeDeploy.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "App"
      type  = "KEY_AND_VALUE"
      value = local.tags.App
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.tags.Environment
    }
  }


  auto_rollback_configuration {
    enabled = false
    events  = ["DEPLOYMENT_FAILURE"]
  }
}