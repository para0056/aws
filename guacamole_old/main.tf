/* 
  Template    : Apache Guacamole
  Author      : Jason Vriends, IT Senior Specialist, Canada Revenue Agency
  Description : Deploy Apache Guacamole using AWS HA design principles (e.g. Elastic Load Balancer, Multi AZ Target Group, Multi AZ Aurora RDS)
  
  Features/Capabilities
  * Deploys AWS Application Load Balancer into two Availability Zones.
  * Deploys AWS Autoscaling Group with a desired capacity of two EC2 instances (one per Availability Zone).
  * Deploys AWS Launch Configuration that automates the deployment of Apache Guacamole.
  * Deploys AWS RDS Aurora mySQL cluster into two Availability Zones.
  * Deploys AWS Security Groups to allow traffic to the AWS Application Load Balancer and EC2 instances.
*/

# Amazon RDS for MySQL (Aurora)
##################################################################

# Cluster
resource "aws_rds_cluster" "guacamole" {
  cluster_identifier      = "guacamole"
  engine                  = "aurora-postgresql"
  availability_zones      = ["ca-central-1a", "ca-central-1b"]
  database_name           = "${var.rds_database_name}"
  master_username         = "${var.rds_master_username}"
  master_password         = "${var.rds_master_password}"
  backup_retention_period = 31
  preferred_backup_window = "01:00-02:00"
  vpc_security_group_ids  = [ "${aws_security_group.guacamole_rds.id}" ]
  db_subnet_group_name    = "${aws_db_subnet_group.guacamole.id}"
  skip_final_snapshot     = "true"  
}

# Instances
resource "aws_rds_cluster_instance" "guacamole" {
  count              = 2
  identifier         = "guacamole-${count.index}"
  cluster_identifier = "${aws_rds_cluster.guacamole.id}"
  instance_class     = "db.t2.small"
  engine             = "aurora-postgresql"
}

# Subnet Group
resource "aws_db_subnet_group" "guacamole" {
  name = "management-subnet-group"
  subnet_ids = ["${var.private_subnet1}","${var.private_subnet2}"]
}

# Creating Launch Configuration
##################################################################

resource "aws_launch_configuration" "guacamole" {
  image_id               = "ami-065ba2b6b298ed80f" # Ubuntu 18.04 LTS | ca-central-1
  instance_type          = "t3.small"
  security_groups        = ["${aws_security_group.guacamole_ec2.id}"]
  key_name               = "AWS-Innovation-Lab"
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              add-apt-repository ppa:guacamole/stable
              apt-get install guacamole-tomcat
              cd /home/ubuntu/
              git clone https://github.com/para0056/apache-guacamole.git
              cd apache-guacamole/local-installation
              sleep $(( ( RANDOM % 60 )  + 1 ))
              ./entrypoint.sh --nginx --mysql-connect --mysql-hostname "${aws_rds_cluster.guacamole.endpoint}" --mysql-db-name "${var.rds_database_name}" --mysql-db-user "${var.rds_master_username}" --mysql-db-user-pwd "${var.rds_master_password}"
              EOF

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Creating Auto Scaling Group
##################################################################

resource "aws_autoscaling_group" "guacamole" {
  launch_configuration = "${aws_launch_configuration.guacamole.id}"
  vpc_zone_identifier  = ["${var.private_subnet1}","${var.private_subnet2}"]
  target_group_arns    = ["${aws_alb_target_group.guacamole.arn}"]
  health_check_grace_period = 600
  min_size = 1
  max_size = 2
  desired_capacity = 2
  health_check_type = "ELB"
  
  tag {
    key = "Name"
    value = "guacamole-asg"
    propagate_at_launch = true
  }

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Creating Elastic Load Balancer
##################################################################

resource "aws_alb" "guacamole" {
  name                             = "guacamole-elb"
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 1800
  subnets                          = ["${var.public_subnet1}","${var.public_subnet2}"]
  security_groups                  = ["${aws_security_group.guacamole_elb.id}"]

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Define a target group
resource "aws_alb_target_group" "guacamole" {
  name     = "guacamole-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.natgw_vpc_id}"
  
  stickiness {
    type = "lb_cookie"
    enabled = "true"
  }

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Define a listener
resource "aws_alb_listener" "guacamole" {
  load_balancer_arn = "${aws_alb.guacamole.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.guacamole.arn}"
    type             = "forward"
  }

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Define a listener rule
resource "aws_alb_listener_rule" "guacamole" {
  listener_arn = "${aws_alb_listener.guacamole.arn}"
  priority     = 99

  action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.guacamole.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/"]
  }

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

resource "aws_autoscaling_attachment" "guacamole" {
  alb_target_group_arn   = "${aws_alb_target_group.guacamole.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.guacamole.id}"

  depends_on = ["aws_rds_cluster_instance.guacamole","aws_rds_cluster.guacamole"]

}

# Deploy Security Groups
##################################################################

# guacamole_elb
resource "aws_security_group" "guacamole_elb" {
  name              = "guacamole_elb"
  description       = "Allow 80 & 443 from proxy to Guacamole ELB"
  vpc_id            = "${var.natgw_vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["${var.onprem_public_cidr_block}"]
    description     = "Allow ingress http traffic from the proxy."
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["${var.onprem_public_cidr_block}"]
    description     = "Allow ingress https traffic from the proxy."
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.vpc_cidr_block}"]
    description     = "Allow egress all traffic to NATGW VPC."
  } 

}

# guacamole_ec2
resource "aws_security_group" "guacamole_ec2" {
  name              = "guacamole_ec2"
  description       = "Allow ingress 80 & 443 from Guacamole ELB to Guacamole EC2 instances."
  vpc_id            = "${var.natgw_vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["${var.vpc_cidr_block}"]
    description     = "Allow ingress http traffic from Guacamole ELB to Guacamole EC2 instances."
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${var.vpc_cidr_block}"]
    description     = "Allow ingress 22 traffic to NAGGW VPC."
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow egress all traffic."
  }  

}

# guacamole_rds
resource "aws_security_group" "guacamole_rds" {
  name              = "guacamole_rds"
  description       = "Allow ingress mySQL traffic from Guacamole EC2 instances."
  vpc_id            = "${var.natgw_vpc_id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["${var.vpc_cidr_block}"]
    description     = "Allow ingress mySQL traffic from Guacamole EC2 instances."
  }

}