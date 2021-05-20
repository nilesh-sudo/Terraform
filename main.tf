# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}
####################################### VPC CREATION ##############################
resource "aws_vpc" "main-vpc" {
  cidr_block           = "192.168.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "production"
  }
}
#################################### SUBNET CREATION ###########################
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = "192.168.0.0/24"
  tags = {
    Name = "production-subnet"
  }
}
################################# IGW ##################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "IGW-main-vpc"
  }
}
###################################### ROUTE TABLE ################################
resource "aws_route_table" "aws_vpc_route_table" {
  vpc_id = aws_vpc.main-vpc.id
 tags = {Name = "aws_vpc_route_table"}
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.aws_vpc_route_table.id
}
################################# NACL ###############################
resource "aws_network_acl" "aws_vpc_NACL" {
  vpc_id     = aws_vpc.main-vpc.id
  subnet_ids = [aws_subnet.subnet-1.id]
  egress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
#    icmp_code       = null
#    icmp_type       = null
#    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }

  ingress {
    action          = "allow"
    cidr_block      = "0.0.0.0/0"
    from_port       = 0
#    icmp_code       = null
#    icmp_type       = null
#    ipv6_cidr_block = ""
    protocol        = "-1"
    rule_no         = 100
    to_port         = 0
  }

  tags = { Name = "AWS_NACL" }
}

resource "aws_security_group" "aws_SG" {
  name        = "SG"
  description = "SSH trafic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
  }
#
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "first-machine" {
  ami                         = "ami-0d5eff06f840b45e9"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.aws_SG.id]
  subnet_id                   = "subnet-0080f3f8f6a1135c4"
  associate_public_ip_address = true
  provisioner "local-exec" {command = "echo hello > hello.txt"}
  tags = {Name = "HelloWorld"}
}
