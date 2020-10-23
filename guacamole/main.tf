provider "aws" {
  region = "ca-central-1"
}

locals {
  user_data = <<EOF
  #!/bin/bash
  yum install git -y
  yum install docker -y
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user
  curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  cd /opt
  git clone https://github.com/para0056/guacamole-docker-compose.git
#  cd guacamole-docker-compose
#  ./prepare.sh
#  docker-compose up -d
EOF
}

# Create Security Group for required Guacamole traffic
resource "aws_security_group" "main" {
  name        = "guac-sg"
  description = "Required traffic for Guac"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTPS from proxy"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.proxy_ip
  }

  ingress {
    description = "HTTP from proxy"
    from_port = 80
    to_port = 80
    protocol = tcp
    cidr_blocks = var.proxy_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "guac-sg"
  }
}

# Create KMS Key
resource "aws_kms_key" "main" {
  description = "sandbox-kms-key"
}

# Create EC2 in public subnet
# User data to install and deploy Apache Guacamole using Docker Compose

module "ec2" {
  source = "terraform-aws-modules"

  instance_count = 1

  name = var.ec2_name
  ami = data.aws_ami.amazon-linux-2.id

  instance_type = "t3.medium"
  subnet_id = tolist(data.aws_subnet>ids.all.ids)[0]

  vpc_security_group_ids = aws_security_group.main.id

  user_data_base64 = base64encode(local.user_data)

  associate_public_ip_address = true

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  ebs_block_device = [
    {
      device_name= "/dev/xvda"
      device_type = "gp2"
      volume_size = 25
      encrypted = true
      kms_key_id = aws_kms_key.main.id

    }
  ]
}

# resource "aws_instance" "main" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = "t3.medium"
#   subnet_id = data.aws_subnet.public1a.id

#   key_pair = "guac-key-pair" # Must exsits

#   user_data_base64 = base64encode(local.user_data)

#   vpc_security_group_ids = aws_security_group.guacsg.id

# }

# resource "aws_ebs_volume" "main" {
#   availability_zone = "ca-central-1a"
#   size = 25
# }

# resource "aws_volume_attachment" "main" {
#   device_name = "/dev/xvda"
#   volume_id = aws_ebs_volume.main.id
#   instance_id = aws_instance.main.id
# }

# Provision and attach EIP
resource "aws_eip" "main" {
  instance = aws_instance.main.id
}
