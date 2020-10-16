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
  git clone https://github.com/para0056/guacamole-docker-compose.git
  cd guacamole-docker-compose
  ./prepare.sh
  docker-compose up -d
EOF
}

# Create Security Group for required Guacamole traffic
resource "aws_security_group" "guacsg" {
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


# Create EC2 in public subnet
# User data to install and deploy Apache Guacamole using Docker Compose
resource "aws_instance" "guac" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  subnet_id = data.aws_subnet.public1a.id

  key_pair = "guac-key-pair" # Must exsits

  user_data_base64 = base64encode(local.user_data)

  vpc_security_group_ids = aws_security_group.guacsg.id

}



# Provision and attach EIP
resource "aws_eip" "lb" {
  instance = aws_instance.guac.id
}