locals {
  app_tags = {
    App = "mongodb"
  }
  tags = merge(var.tags, local.app_tags)
}
