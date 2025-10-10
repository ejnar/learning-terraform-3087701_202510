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

  subnet_id     = subnet-12a8ab3f  # Explicitly specify subnet
  vpc_security_group_ids = sg-feb60481 # use IDs

  tags = {
    Name = "HelloWorld"
  }
}
