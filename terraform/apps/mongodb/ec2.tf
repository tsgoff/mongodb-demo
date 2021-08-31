resource "aws_instance" "ec2-mongodb" {
  count = var.instance_count
  ami = data.aws_ami.ubuntu18.id
  instance_type = var.instance_type
  monitoring = true
  vpc_security_group_ids = [ aws_security_group.mongodb.id ]
  subnet_id              = element(coalesce(var.subnet_ids, data.aws_subnet_ids.default.ids), count.index)

  key_name = "demo-${local.tags.Environment}"
  
  iam_instance_profile = "${local.tags.Project}-${local.tags.App}-instance-profile-${local.tags.Environment}"

  user_data = coalesce(
  var.user_data,
  templatefile(
  "${path.module}/templates/userdata.tpl",
  {
    hostname    = "${local.tags.Project}-${local.tags.App}-${format("%02d", count.index + 1)}-${local.tags.Environment}"

    Environment = var.tags.Environment
    App         = "${local.tags.Project}-${local.tags.App}"
    domain      = "example.com"
    installApm  = true

    Environment = local.tags.Environment
    App         = "${local.tags.Project}-${local.tags.App}"
    Project     = local.tags.Project


  }
  )
  )

  ebs_optimized = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    delete_on_termination = true
  }

  ebs_block_device  {
    device_name = "/dev/sdb"
    volume_size = var.volume_size
    volume_type = "gp3"
  }


  tags = {
    Name = "${local.tags.Project}-${local.tags.App}-${format("%02d", count.index + 1)}-${local.tags.Environment}.example.com"
    App = local.tags.App
    Environment = local.tags.Environment
    Project = local.tags.Project
  }

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_key_pair" "demo" {
  key_name   = "demo-${local.tags.Environment}"
  public_key = var.public_key
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.tags.Project}-${local.tags.App}-instance-role-${local.tags.Environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.tags.Project}-${local.tags.App}-instance-profile-${local.tags.Environment}"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy" "ec2_instance_policy" {
  name = "${var.tags.Project}-${local.tags.App}-CodeDeploy-s3access-${var.tags.Environment}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "s3:Get*",
                  "s3:List*"
              ],
              "Resource": [
                  "arn:aws:s3:::deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/codedeploy/${var.tags.Project}-${local.tags.App}-${local.tags.Environment}/*",
                  "arn:aws:s3:::deploy-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/codedeploy/${var.tags.Project}-${local.tags.App}-${local.tags.Environment}"
              ],
              "Effect": "Allow"
          }
      ]
  }
EOF
}

resource "aws_iam_role_policy" "ec2_iam_instance_policy" {
  name = "${var.tags.Project}-${local.tags.App}-iam-${var.tags.Environment}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:ListAccountAliases",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy_ec2_ro" {
  name = "${var.tags.Project}-${local.tags.App}-EC2-read-only-${var.tags.Environment}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy_ssm" {
  name = "${var.tags.Project}-${local.tags.App}-ssm-${var.tags.Environment}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter*"
            ],
            "Resource": "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.tags.Project}/${local.tags.App}/${var.tags.Environment}/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_instance_policy_s3_backup" {
  name = "${var.tags.Project}-${local.tags.App}-s3-backup-${var.tags.Environment}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "s3:Get*",
                  "s3:List*",
                  "s3:AbortMultipartUpload",
                  "s3:PutObject"
              ],
              "Resource": [
                  "arn:aws:s3:::${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}/*",
                  "arn:aws:s3:::${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}",
                  "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:accesspoint/${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}",
                  "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:accesspoint/${var.tags.Project}-${local.tags.App}-backup-${var.tags.Environment}/*"
              ],
              "Effect": "Allow"
          }
      ]
  }
EOF
}