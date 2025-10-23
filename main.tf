data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}


# ------------------------------
# 1. Create VPC
# ------------------------------
#resource "aws_vpc" "main" {
#  cidr_block           = "10.0.0.0/16"
#  enable_dns_support   = true
#  enable_dns_hostnames = true
#  tags = {
#    Name = "my-vpc"
#  }
#}

# ------------------------------
# 2. Create Subnet
# ------------------------------
#resource "aws_subnet" "public_subnet" {
#  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "10.0.1.0/24"
#  map_public_ip_on_launch = true
#  availability_zone       = "us-west-2a"
#
#  tags = {
#    Name = "public-subnet"
#  }
#}


# ------------------------------
# 3. Create Internet Gateway
# ------------------------------
#resource "aws_internet_gateway" "igw" {
#  vpc_id = aws_vpc.main.id
#  tags = {
#    Name = "my-igw"
#  }
#}

# ------------------------------
# 4. Create Route Table and Route
# ------------------------------
#resource "aws_route_table" "public_rt" {
#  vpc_id = aws_vpc.main.id
#  tags = {
#    Name = "public-route-table"
#  }
#}

#resource "aws_route" "internet_access" {
#  route_table_id         = aws_route_table.public_rt.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.igw.id
#}

# ------------------------------
# 5. Associate Subnet with Route Table
# ------------------------------
#resource "aws_route_table_association" "public_assoc" {
#  subnet_id      = aws_subnet.public_subnet.id
#  route_table_id = aws_route_table.public_rt.id
#}


resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.web_security_group.security_group_id]
  subnet_id              = module.web_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "web_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  azs             = ["us-west-2a"]
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.3.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "web_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"
  name = "web_sg"

  vpc_id              = module.web_vpc.vpc_id

  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }

}
