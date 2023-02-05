provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "Altschool-vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "Altschool-vpc"
  }
}

resource "aws_internet_gateway" "Altschool-internet-gateway" {
  vpc_id = aws_vpc.Altschool-vpc.id

  tags = {
    Name = "Internet gateway"
  }
}

resource "aws_route_table" "Route-table" {
  vpc_id = aws_vpc.Altschool-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Altschool-internet-gateway.id
  }

  tags = {
    Name = "Route-table"
  }
}

resource "aws_subnet" "Altschool-public-subnet1" {
  vpc_id                    = aws_vpc.Altschool-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone     = "us-east-1a"
}


resource "aws_subnet" "Altschool-public-subnet2" {
  vpc_id                    = aws_vpc.Altschool-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.2.0/24"
  availability_zone      = "us-east-1b"
}


resource "aws_network_acl" "Altschool-network_acl" {
  vpc_id = aws_vpc.Altschool-vpc.id
  subnet_ids = [aws_subnet.Altschool-public-subnet1.id, aws_subnet.Altschool-public-subnet2.id]

ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "Altschool-LB_sg" {
  name        = "Altschool-LB_sg"
  description = "security group for the load balancer"
  vpc_id      = aws_vpc.Altschool-vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Security-group-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow ssh, Http and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.Altschool-vpc.id

   ingress {
     description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-LB_sg.id]
    }
   
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-LB_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Altschool1" {
  ami                 = "ami-00874d747dde814fa"
  instance_type       = "t2.micro"
  key_name            = "another"
  security_groups     = [aws_security_group.Security-group-rule.id]
 subnet_id            = aws_subnet. Altschool-public-subnet1.id
  availability_zone  = "us-east-1a"
  tags = {
    Name = "Altschool-1"
    source = "terraform"
  }
}

resource "aws_instance" "Altschool2" {
  ami                 = "ami-00874d747dde814fa"
  instance_type       = "t2.micro"
  key_name            = "another"
  security_groups     = [aws_security_group.Security-group-rule.id]
 subnet_id            = aws_subnet.Altschool-public-subnet2.id
  availability_zone  = "us-east-1b"
  tags = {
    Name = "Altschool=2"
    source = "terraform"
  }
}
  
resource "aws_instance" "Altschool3" {
  ami                 = "ami-00874d747dde814fa"
  instance_type       = "t2.micro"
  key_name            = "another"
  security_groups     = [aws_security_group.Security-group-rule.id]
 subnet_id            = aws_subnet.Altschool-public-subnet1.id
  availability_zone  = "us-east-1a"
  tags = {
    Name = "Altschool-3"
    source = "terraform"
  }
}  
  
 resource "local_file" "Ip_address" {
  filename = "/TERRAFORM PROJ/host-inventory"
  content  = <<EOT
${aws_instance.Altschool1.public_ip}
${aws_instance.Altschool2.public_ip}
${aws_instance.Altschool3.public_ip}
  EOT
} 

resource "aws_lb" "Altschool-LB" {
  name               = "Altschool-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Altschool-LB_sg.id]
  subnets            = [aws_subnet.Altschool-public-subnet1.id, aws_subnet.Altschool-public-subnet2.id]
enable_deletion_protection = false
depends_on            = [aws_instance.Altschool1, aws_instance.Altschool2, aws_instance.Altschool3]
}
resource "aws_lb_target_group" "Altschool-target-group" {
  name     = "Altschool-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Altschool-vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "Altschool-listener" {
  load_balancer_arn = aws_lb.Altschool-LB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
}

resource "aws_lb_listener_rule" "Altschool-listener-rule" {
  listener_arn = aws_lb_listener.Altschool-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment2" {
 target_group_arn = aws_lb_target_group.Altschool-target-group.arn
 target_id        = aws_instance.Altschool2.id
 port             = 80
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment3" {
 target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool3.id
  port             = 80
}










