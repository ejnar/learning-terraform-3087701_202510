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

module "web_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "dev"
  cidr = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnets = ["10.0.5.0/24","10.0.6.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.0"
  name = "web"
  
  min_size = 1
  max_size = 2

  vpc_zone_identifier = module.web_vpc.public_subnets
  target_group_arns   = module.web_alb.target_group_arns
  security_groups     = [module.web_sg.security_group_id]

  instance_type       = var.instance_type
  image_id            = data.aws_ami.app_ami.id
}

module "web_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name               = "web-alb"
  load_balancer_type = "application"

  vpc_id          = module.web_vpc.vpc_id
  subnets         = module.web_vpc.public_subnets 
  security_groups = [module.web_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "web-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}

module "web_sg" {
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