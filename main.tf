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

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  subnet_id              = module.web_vpc.public_subnets[0] 
  vpc_security_group_ids = [module.web_security_group.security_group_id]
  
  associate_public_ip_address = true  # 👈 Required for public DNS

  tags = {
    Name = "HelloWorld"
    Environment = "dev"
  }
}

# ========================
# 4. ALB Target Group
# ========================
#resource "aws_lb_target_group" "web" {
#  name     = "web-tg"
#  port     = 80
#  protocol = "HTTP"
#  vpc_id   = module.web_vpc.vpc_id
#
#  health_check {
#    path                = "/"
#    protocol            = "HTTP"
#    interval            = 30
#    timeout             = 5
#    healthy_threshold   = 5
#    unhealthy_threshold = 2
#  }
#}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name               = "web-alb"
  load_balancer_type = "application"

  vpc_id          = module.web_vpc.vpc_id
  subnets         = module.web_vpc.public_subnets 
  security_groups = [module.web_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "web-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = aws_instance.web.id
          port = 80
        }
      }
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


module "web_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "dev"
  cidr = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  azs             = ["us-west-2a"]
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.3.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

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
