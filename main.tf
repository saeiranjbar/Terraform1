variable "input_port" {
  description = "This is the web server input port"
  type = number
  default = 8080
}
provider "aws" {
  region = "us-east-2"
}
resource "aws_instance" "web" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]
    user_data = <<-EOF
      #!/bin/bash
      echo "Hello World!" > index.html
      nohup busybox httpd -f -p ${var.input_port} &
    EOF

    tags = {
      name = "Web Server"
    }
}

resource "aws_security_group" "instance" {
  name = "Webserver"
  ingress {
    from_port = var.input_port
    to_port = var.input_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "Public_IP" {
  value = aws_instance.web.public_ip
}
