
resource "random_password" "adminpassword" {
  length = 15
  special = false
}

resource "random_password" "demopassword" {
  length = 15
  special = false
}

data "external" "openssl" {
  program = ["bash", "../../apps/mongodb/openssl.sh"]

  query = {
    key = "key"
  }

}

resource "aws_ssm_parameter" "adminpw" {
  name        = "/${local.tags.Project}/${local.tags.App}/${local.tags.Environment}/adminpw"
  type        = "SecureString"
  value       = random_password.adminpassword.result
  tags = local.tags
}

resource "aws_ssm_parameter" "demopw" {
  name        = "/${local.tags.Project}/${local.tags.App}/${local.tags.Environment}/demopw"
  type        = "SecureString"
  value       = random_password.demopassword.result
  tags = local.tags
}

resource "aws_ssm_parameter" "cluster_key" {
  name        = "/${local.tags.Project}/${local.tags.App}/${local.tags.Environment}/cluster_key"
  type        = "SecureString"
  value       = data.external.openssl.result.key
  tags = local.tags
}