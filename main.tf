##############################################
# VPC
##############################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_nat_gateway = false

  tags = {
    Environment = "demo"
  }
}

##############################################
# Security Group for ALB
##############################################
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "alb-sg"
  description = "Allow HTTP access"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]
}

##############################################
# ALB (New Syntax for v9+)
##############################################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.0.0"

  name               = "demo-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  # define listeners (new structure)
  listeners = {
    http = {
      port            = 80
      protocol        = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "web"
      }
    }
  }

  target_groups = {
    web = {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        path = "/"
        protocol = "HTTP"
      }
    }
  }

  tags = {
    Environment = "demo"
  }
}

##############################################
# Security Group for EC2
##############################################
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "ec2-sg"
  description = "Allow traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

##############################################
# Auto Scaling Group
##############################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.0"

  name                = "demo-asg"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = module.vpc.public_subnets

  # Launch template defaults (replaces launch_template)
  launch_template_defaults = {
    image_id      = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    key_name      = var.key_name

    user_data = base64encode(<<-EOF
                #!/bin/bash
                yum install -y httpd
                echo "Hello from $(hostname)" > /var/www/html/index.html
                systemctl enable httpd
                systemctl start httpd
                EOF
    )

    network_interfaces = [
      {
        security_groups = [module.ec2_sg.security_group_id]
      }
    ]
  }

  # Attach ALB target groups
  target_groups = [module.alb.target_groups["web"].arn]

  tags = [
    {
      key                 = "Name"
      value               = "demo-instance"
      propagate_at_launch = true
    }
  ]
}