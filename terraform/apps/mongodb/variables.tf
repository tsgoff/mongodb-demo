variable "tags" {
  type = map
}

variable "disable_api_termination" {
  type    = bool
  default = false
}

variable "instance_count" {
  default = "1"
}

variable "instance_type" {
  default = "t4g.micro"
}

variable "root_volume_size" {
  default = "15"
}

variable "volume_size" {
  default = "20"
}

variable "region" {
  default = "us-east-1"
}

variable "user_data" {
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "subnet list"
  type        = list(string)
  default     = null
}

variable "public_key" {}