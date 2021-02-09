variable "server_port" {
  default = "8080"
}
provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "ALC" {
    image_id = "ami-0c55b159cbfafe1f0"
    security_groups = []
    instance_type = "t2.micro"
    user_data = <<-EOF
    #!/bin/bash
      echo "Hello World" > index.html
      nohup busybox httpd -f -p ${var.server_port} &
      EOF
    lifecycle {
      create_before_destroy = true
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.ALC.id
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    min_size = 2
    max_size = 5
    desired_capacity = 2
}
