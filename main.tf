# Provider configuration - setting the AWS region
provider "aws" {
  region = "us-west-2"
}

# Create a Virtual Private Cloud (VPC) to hold all network components
resource "aws_vpc" "multi_tier_vpc" {
  cidr_block = "192.168.0.0/16"  # IP range for the VPC
  tags = {
    Name = "MultiTierVPC"  # Tag for easier identification
  }
}

# Create a public subnet for resources that need internet access
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.multi_tier_vpc.id
  cidr_block = "192.168.1.0/24"  # Subnet range
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true  # Enable public IP for instances in this subnet
  tags = {
    Name = "PublicSubnet"
  }
}

# Create private subnets for application servers and database
resource "aws_subnet" "private_subnet_app1" {
  vpc_id     = aws_vpc.multi_tier_vpc.id
  cidr_block = "192.168.2.0/24"  # First private subnet for app server 1
  availability_zone = "us-west-2a"
  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet_app2" {
  vpc_id     = aws_vpc.multi_tier_vpc.id
  cidr_block = "192.168.3.0/24"  # Second private subnet for app server 2
  availability_zone = "us-west-2a"
  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_subnet" "private_subnet_db" {
  vpc_id     = aws_vpc.multi_tier_vpc.id
  cidr_block = "192.168.4.0/24"  # Private subnet for database
  availability_zone = "us-west-2b"
  tags = {
    Name = "PrivateSubnet3"
  }
}

# Create an Internet Gateway to enable internet access for the public subnet
resource "aws_internet_gateway" "multi_tier_igw" {
  vpc_id = aws_vpc.multi_tier_vpc.id
  tags = {
    Name = "MultiTierIGW"
  }
}

# Create a NAT Gateway to allow outbound internet access for instances in private subnets
resource "aws_eip" "nat_eip" {
  vpc = true  # Elastic IP for the NAT Gateway
}

resource "aws_nat_gateway" "multi_tier_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id  # NAT Gateway is placed in the public subnet
  tags = {
    Name = "MultiTierNATGateway"
  }
}

# Create a Route Table for the public subnet with a route to the internet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.multi_tier_vpc.id
  route {
    cidr_block = "0.0.0.0/0"  # Route all outbound traffic to the internet
    gateway_id = aws_internet_gateway.multi_tier_igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a Route Table for private subnets with a route to the NAT Gateway for internet access
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.multi_tier_vpc.id
  route {
    cidr_block = "0.0.0.0/0"  # Route traffic through the NAT Gateway
    nat_gateway_id = aws_nat_gateway.multi_tier_nat.id
  }
  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private_route_assoc1" {
  subnet_id      = aws_subnet.private_subnet_app1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_assoc2" {
  subnet_id      = aws_subnet.private_subnet_app2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_assoc_db" {
  subnet_id      = aws_subnet.private_subnet_db.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create security group for Bastion Host, allowing SSH access
resource "aws_security_group" "sg_bastion" {
  vpc_id = aws_vpc.multi_tier_vpc.id

  ingress {
    from_port   = 22  # Allow SSH (port 22) access
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Update this to your trusted IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Bastion"
  }
}

# Create security group for Web Server, allowing HTTP traffic
resource "aws_security_group" "sg_web" {
  vpc_id = aws_vpc.multi_tier_vpc.id

  ingress {
    from_port   = 80  # Allow HTTP (port 80) traffic from anywhere
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-WebServer"
  }
}

# Create security group for App Server, allowing MySQL traffic only from Web Server
resource "aws_security_group" "sg_app" {
  vpc_id = aws_vpc.multi_tier_vpc.id

  ingress {
    from_port   = 3306  # Allow MySQL (port 3306) traffic
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_web.id]  # Restrict access to Web Server security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-AppServer"
  }
}

# Create security group for Database, allowing MySQL traffic only from App Server
resource "aws_security_group" "sg_db" {
  vpc_id = aws_vpc.multi_tier_vpc.id

  ingress {
    from_port   = 3306  # Allow MySQL (port 3306) traffic
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_app.id]  # Restrict access to App Server security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Database"
  }
}

# Launch an EC2 instance for the Bastion Host (for administrative SSH access)
resource "aws_instance" "bastion" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"  # Instance type
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg_bastion.name]  # Assign Bastion security group

  key_name = "your-key-pair"  # SSH key for access

  tags = {
    Name = "BastionHost"
  }
}

# Launch an EC2 instance for the Web Server
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"  # Instance type
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg_web.name]  # Assign Web Server security group

  key_name = "your-key-pair"  # SSH key for access

  tags = {
    Name = "WebServer"
  }
}

# Launch an EC2 instance for the App Server
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"  # Instance type
  subnet_id     = aws_subnet.private_subnet_app1.id
  security_groups = [aws_security_group.sg_app.name]  # Assign App Server security group

  key_name = "your-key-pair"  # SSH key for access

  tags = {
    Name = "AppServer"
  }
}

# Create an RDS subnet group for the database
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "DBSubnetGroup"
  subnet_ids = [
    aws_subnet.private_subnet_db.id  # Associate the private DB subnet
  ]
}

# Create an RDS instance for the database
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 20  # Storage for the database
  engine               = "mariadb"  # Database engine
  instance_class       = "db.t2.micro"  # Instance size
  name                 = "mydb"  # Initial database name
  username             = "root"  # Admin username
  password             = "Re:Start!9"  # Admin password
  vpc_security_group_ids = [aws_security_group.sg_db.id]  # Assign DB security group
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name  # Associate the subnet group
  skip_final_snapshot  = true  # Skip snapshot when deleting
  backup_retention_period = 0  # Disable backups
  publicly_accessible  = false  # Private DB instance (not publicly accessible)
  availability_zone    = "us-west-2a"  # Availability zone for the instance
}
