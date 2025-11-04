output "alb_dns_name" {
  value = module.alb.lb_dns_name
}

output "asg_name" {
  value = module.asg.autoscaling_group_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}


