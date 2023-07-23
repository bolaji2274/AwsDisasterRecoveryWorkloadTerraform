

# variable "server_port" {
#   description = "This is a server port number"
#   type        = number
#   default     = 8080
# }
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


# provider "aws" {
#   region = "us-east-2"
# }
# # This will prevent the terraform from being destroy
# resource "aws_s3_bucket" "hb-s3-state" {
#   bucket = "hb-terraform-state"

#   # lifecycle {
#   #   # prevent_destroy = true
#   # }
# }

# # Enable versioning so you can see the full revision history of your
# # state files
# resource "aws_s3_bucket_versioning" "enabled" {
#   bucket = aws_s3_bucket.hb-s3-state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Enable server side encryption by default
# resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
#   bucket = aws_s3_bucket.hb-s3-state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
 
# # Explicitly block all public ip address access to the s3 bucket
# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket = aws_s3_bucket.hb-s3-state.id
#   block_public_acls = true
#   block_public_policy = true
#   ignore_public_acls = true
#   restrict_public_buckets = true
# }

# # use DynamoDB for locking with Terraform in s3 bucket
# resource "aws_dynamodb_table" "terraform_locks" {
#   name = "hb-terraform-state-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key = "LockID"
  
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }




provider "aws" {
  region = "us-east-1"
}

# Creating an aws instance
resource "aws_instance" "testing" {
  ami = "ami-05dd1b6e7ef6f8378"
  instance_type = "t2.micro"
  key_name = "web"
  subnet_id = aws_subnet.main-subnet.id
  vpc_security_group_ids = [ aws_security_group.main-vpc-sg.id ]
}


# Creating a Main VPC
resource "aws_vpc" "main-vpc" {
  enable_dns_hostnames = true
  enable_dns_support = true
  cidr_block = "10.10.0.0/16"
}


# Creating a subnet inside our main VPC
resource "aws_subnet" "main-subnet" {
  vpc_id = aws_vpc.main-vpc.id
  cidr_block = "10.10.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
}

# Creating an internet gateway inside main vpc
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main-iqw"
  }
}

# Creating a route table for main vpc
resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "main-rt"
  }
}

# Creating subnet association to associate our subnet with route table
resource "aws_route_table_association" "main-rt-association" {
  subnet_id = aws_subnet.main-subnet.id
  route_table_id = aws_route_table.main-rt.id
}

# Creating a security group for our main vpc
resource "aws_security_group" "main-vpc-sg" {
  name = "main-vpc-sg"
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  tags = {
    Name = "main-vpc-sg"
  }
}
output "public_ip" {
  value       = aws_instance.testing.public_ip
  description = "The public ip address of a webserver"
}

