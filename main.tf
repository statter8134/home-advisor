provider "aws" {region = "us-west-2"}

variable "vpc_id" {
}

variable "ssh_keypair" {
}

variable "resource_prefix" {
  
}

variable "ec2_instance_type" {
  default = "t2.medium"
}


resource "aws_security_group" "instances" {
  name        = "k3s-${var.resource_prefix}"
  description = "k3s-${var.resource_prefix}"
  vpc_id      = var.vpc_id
  }

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "TCP"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}
resource "aws_security_group_rule" "outbound_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "inbound_allow_all" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "kubeapi" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "TCP"
  self            = true  
  security_group_id = aws_security_group.instances.id

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"] # Ubuntu Minimal Bionic
    }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  }

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmwWMOzhoonS9VlOYBPodZPIgEdPg/z+OxbYMc0/27wTTBVZ9SupW7Jt0RtZWX3xo3hP9CbdL/I/ZGZY0n3eieY8NKAheGn5cokOcrn+VxLZ0p/S0m4LP2049Id+FJY1D1YNYRGTXdSuzAUp3kwA0f8blgX7zbZ5qq0wF/+C6Bd8eV5W2Ww5YG6QiRzSY/h+7FM2jXpd4RLwpi0bPc+iUlaphBdIblDe6mY/xc2DCiAnDKgiZeXo3dTTrXEc20ufOXKtnDHBP0UQK/I93sRWkK3vlD01ZxGItx+aLdLGYRTcHiA/0MO7f8wfbTLdjc8jEZHwtFzKcP1TkJsVssSayR rhyscolorado@gmail.com"
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  user_data = file("cloud-config-server.yml")
#  key_name = "${var.ssh_keypair}"
  key_name = "deployer-key"
  vpc_security_group_ids = ["${aws_security_group.instances.id}"]
  tags = {
    Name = "${var.resource_prefix}-k3s-server"
  }
}

resource "aws_instance" "worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  user_data = file("cloud-config-worker.yml")
#  key_name = "${var.ssh_keypair}"
  key_name = "deployer-key"
  vpc_security_group_ids = ["${aws_security_group.instances.id}"]
  tags = {
    Name = "${var.resource_prefix}-k3s-worker"
  }
}
