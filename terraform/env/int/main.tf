locals {
  env_tags = {
    Environment = "int"
    Terraform   = "true"
    Project     = "demo"
  }
}

module "mongodb" {
  source = "../../apps/mongodb"
  tags   = local.env_tags
  disable_api_termination = false
  instance_count          = 3
  instance_type           = "t4g.nano"
  root_volume_size        = "15"
  volume_size             = "10"
  public_key              = var.public_key
}
