# Apache Guacamole

Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like SSC, Telnet, VNC, and RDP. It is open source and requires no plugins or client software installed. Thanks to HTML5, once Guacamole is installed on a server, all you need to access your remote desktops and servers is a web browser.
Since Apache Guacamole is accessed via your web browser, you can install Guacamole on a Cloud Service Provider and access Apache Guacamole through your corporate proxy server. This can enable you to remotely access your Cloud hosted virtual machines without having to configure Firewall Rules or establish a Virtual Private Network.

## Prerequisites

* To deploy this solution, you need the following:
  * AWS Account
  * A Virtual Machine with Terraform

## Features/Capabilities

* Deploys AWS Application Load Balancer into two Availability Zones.
* Deploys AWS Autoscaling Group with a desired capacity of two EC2 instances (one per Availability Zone).
* Deploys AWS Launch Configuration that automates the deployment of Apache Guacamole.
* Deploys AWS RDS Aurora mySQL cluster into two Availability Zones.
* Deploys AWS Security Groups to allow traffic to the AWS Application Load Balancer and EC2 instances.

## Security/Design Considerations
* Traffic to the AWS Application Load Balancer is restricted to your external CIDR.
* Traffic to the AWS EC2 instances of Apache Guacamole are restricted to the VPC CIDR block.
* AWS will automatically provision new EC2 instances across the two Canada Central Availability Zones based on load and health.
* **Purchase a domain using Route 53 and deploy a SSL certificate using the Amazon Certificate Manager*/*

## Feature Backlog
* SSO based on AWS SSO

## Deployment

1. Clone this repo into a Virtual Machine
2. Create a terraform.tfvars file and populate this file with the following variables:

```
# AWS CLI Credentials to Network Security AWS Account
access_key = ""
secret_key = ""

# RDS Information
rds_database_name = "some_db_name"
rds_master_username = "some_username"
rds_master_password = "some_password"

# NATGW Outside Subnet 1A
public_subnet1 = "subnet-xxxxxxxxxxxxxxxxx"

# NATGW Outside Subnet 2A
public_subnet2 = "subnet-xxxxxxxxxxxxxxxxx"

# NATGW Inside Subnet 1A
private_subnet1 = "subnet-xxxxxxxxxxxxxxxxx"

# NATGW Inside Subnet 2A
private_subnet2 = "subnet-xxxxxxxxxxxxxxxxx"

# NATGW VPC
natgw_vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# External CIDR (restricts external access to Apache Guacamole to this CIDR)
onprem_public_cidr_block = "x.x.x.x/32"

# NATGW VPC CIDR (allows inbound SSH and RDP access to EC2 instances to only this CIDR)
vpc_cidr_block = "100.97.x.x/24"
```

3. Execute the command **terraform apply** in the **Apache Guacamole IaC** directory.
   * Confirm the deployment be entering **yes** and pressing **enter**.