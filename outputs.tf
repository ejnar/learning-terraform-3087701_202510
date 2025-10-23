output "instance_ami" {
  value = aws_instance.web.ami
}

output "instance_arn" {
  value = aws_instance.web.arn
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}
