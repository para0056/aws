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