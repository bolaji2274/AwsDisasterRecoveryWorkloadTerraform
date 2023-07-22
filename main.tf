

# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_instance" "webserver" {
#   ami                         = "ami-0fb653ca2d3203ac1"
#   instance_type               = "t2.micro"
#   vpc_security_group_ids      = [aws_security_group.instance.id]
#   user_data                   = <<-EOF
#             #!/bin/bash
#             echo "Hello Bolaji Hammed" > index.html
#             nohup busybox httpd -f -p ${var.server_port} &
#             EOF
#   user_data_replace_on_change = true



#   tags = {
#     name = "web"
#   }
# }

# resource "aws_security_group" "instance" {
#   name = "terraform-web"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# output "public_ip" {
#   value       = aws_instance.webserver.public_ip
#   description = "The public ip address of a webserver"
# }

resource "aws_security_group" "instance" {
  name = "terraform-web"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "web" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data                   = <<-EOF
            #!/bin/bash
            echo "Hello Bolaji Hammed" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF
  
  lifecycle {
    # updating any references that were pointing at the old resource to point to the replacement
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [ aws_alb_target_group.asg.arn ]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key = "Name"
    value = "terraform-asg-web"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Deploy a Load balancer


resource "aws_lb" "web_lb" {
  name = "terraform-asg-web"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-web-alb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0"]

  }
}

resource "aws_alb_target_group" "asg" {
  name = "terraform-asg-alb-tg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2

  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.web_lb.dns_name
  description = "The domain name of the load balancer"
}






variable "server_port" {
  description = "This is a server port number"
  type        = number
  default     = 8080
}