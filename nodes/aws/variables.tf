variable "aws_priv_key" {
  default = "~/.ssh/proxycannon.pem"
}

variable "mainKey" {}
# number of exit-node instances to launch
variable "countOf" {
  default = 2
}

# launch all exit nodes in the same subnet id
# this should be the same subnet id that your control server is in
# you can get this value from the AWS console when viewing the details of the control-server instance
variable "subnet-id" {
}

variable "vpc_id" {}
