provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "Web-server" {
    ami = "ami-03d6336a"
    instance_type = "t2.micro"

    tags = {
      name = "Web Server"
    }

    user_data =  <<-EOF
                  #!/bin/bash
                  echo "Hello, World" > index.html
                  nohup busybox httpd -f -p 8080 &
                  EOF
    vpc_security_group_ids = [aws_security_group.instance.id]
}
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
