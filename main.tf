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
  instance_type = "t3.nano"

  subnet_id     = aws_subnet.subnet-12a8ab3f.id  # Explicitly specify subnet
  vpc_security_group_ids = [aws_security_group.sg-feb60481.id] # use IDs

  tags = {
    Name = "HelloWorld"
  }
}
