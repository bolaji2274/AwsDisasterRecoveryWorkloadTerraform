variable "server_port" {
  description = "This is a server port number"
  type        = number
  default     = 8080
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "webserver" {
  ami                         = "ami-0fb653ca2d3203ac1"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.instance.id]
  user_data                   = <<-EOF
            #!/bin/bash
            echo "Hello Bolaji Hammed" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF
  user_data_replace_on_change = true



  tags = {
    name = "web"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-web"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value       = aws_instance.webserver.public_ip
  description = "The public ip address of a webserver"
}
