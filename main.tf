variable "server_port" {
  default = 8080
  description = "Valid port for incoming traffic"
}

provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "frontend" {
    name = "lc"
    image_id = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.web.id]

    user_data = <<-EOF
    #!/bin/bash/
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "frontend" {
    name = "asg"
    launch_configuration = aws_launch_configuration.frontend.name
    min_size = 2
    max_size = 4
    desired_capacity = 3
    health_check_type = "ELB"
    vpc_zone_identifier = data.aws_subnet_ids.subnets.ids
    target_group_arns = [aws_lb_target_group.test.arn]
}

resource "aws_security_group" "web" {
    ingress {
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_lb" "frontend" {
  name               = "frontend"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = data.aws_subnet_ids.subnets.ids
}

resource "aws_security_group" "lb_sg" {
    name = "lbsg"
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "test" {
  name     = "lb-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 15
    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }
}

resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.frontend.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

output "lb_dns_name" {
  value = aws_lb.frontend.dns_name
}
