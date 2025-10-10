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

data "aws_subnet" "existing_sub" {
  id = "subnet-12a8ab3f"
}

data "aws_security_group" "existing_sg" {
  id = "sg-feb60481"
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t3.nano"

  subnet_id     = data.aws_subnet.existing_sub.id                # Explicitly specify subnet
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]   # use IDs

  tags = {
    Name = "HelloWorld"
  }
}
