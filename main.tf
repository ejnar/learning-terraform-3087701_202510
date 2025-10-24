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

resource "aws_instance" "web" { 
  ami = data.aws_ami.app_ami.id 
  instance_type = var.instance_type

  subnet_id = module.web_vpc.public_subnets[0] 
  vpc_security_group_ids = [module.web_sg.security_group_id]

  associate_public_ip_address = true # 👈 Required for public DNS

  tags = { 
    Name = "HelloWorld" 
    Environment = "dev" 
  } 
}

#module "autoscaling" {
#  source  = "terraform-aws-modules/autoscaling/aws"
#  version = "6.5.2"
#  name = "web"
#  
#  min_size = 1
#  max_size = 2
#
#  vpc_zone_identifier = module.web_vpc.public_subnets
#  target_group_arns   = module.web_alb.target_group_arns
#  security_groups     = [module.web_sg.security_group_id]
#
#  instance_type       = var.instance_type
#  image_id            = data.aws_ami.app_ami.id
#}

resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.web_vpc.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

module "web_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name               = "web-alb"
  load_balancer_type = "application"

  vpc_id          = module.web_vpc.vpc_id
  subnets         = module.web_vpc.public_subnets 
  security_groups = [module.web_sg.security_group_id]

  # Access logs (optional)
  enable_deletion_protection = false
  internal                   = false
  idle_timeout               = 60

  # Listener for HTTP
  http_tcp_listeners = [
    {
      port                = 80
      protocol            = "HTTP"
      #default_action_type = "forward"
      target_group_index  = 0
      #target_group_arn    = aws_lb_target_group.web.arn
    }
  ]

  tags = {
    Environment = "dev"
  }
}

module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"
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