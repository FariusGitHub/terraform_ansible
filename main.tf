
provider "aws" {
  region = "us-east-1"
  access_key = "..."
  secret_key = "..."
}

resource "aws_vpc" "vpc-project2" {
    cidr_block = "10.2.0.0/16"
    tags = {
    Name = "vpc-project2"
    }
}

resource "aws_subnet" "pub-subnet" {
    vpc_id = aws_vpc.vpc-project2.id
    cidr_block = "10.2.254.0/24"
    tags = {
    Name = "pub-subnet"
    }
}

resource "aws_subnet" "prv-subnet" {
    vpc_id = aws_vpc.vpc-project2.id
    cidr_block = "10.2.2.0/24"
    tags = {
    Name = "prv-subnet"
    }
}

resource "aws_internet_gateway" "igw-vpc-project2" {
    vpc_id = aws_vpc.vpc-project2.id
    tags = {
    Name = "igw-vpc-project2"
    }
}

resource "aws_route_table" "rt-pub-project2" {
vpc_id = aws_vpc.vpc-project2.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw-vpc-project2.id
}
tags = {
Name = "rt-pub-project2"
}
}

resource "aws_route_table_association" "rt-pub_association-project2" {
    subnet_id = aws_subnet.pub-subnet.id
    route_table_id = aws_route_table.rt-pub-project2.id
}

resource "aws_security_group" "sg_api_project2" {
  name        = "sg_api_project2"
  description = "sg_api_project2"
  vpc_id      = aws_vpc.vpc-project2.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "sg_api_project2"
  }
}

resource "aws_security_group" "sg_pdb_project2" {
  name        = "sg_pdb_project2"
  description = "sg_pdb_project2"
  vpc_id      = aws_vpc.vpc-project2.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "sg_pdb_project2"
  }
}

resource "aws_instance" "PRIVATEDB" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name      = "wcd-projects"
  subnet_id     = aws_subnet.prv-subnet.id
  vpc_security_group_ids = [
    aws_security_group.sg_pdb_project2.id
  ]
  associate_public_ip_address = false
  tags = {
    Name = "PRIVATEDB"
  }

  user_data = file("dbinstall.txt")
}

resource "aws_launch_template" "EC2_template_project2" {
  name                      = "EC2_template_project2"
  image_id                  = "ami-0fc5d935ebf8bc3bc"
  instance_type             = "t2.micro"
  key_name                  = "wcd-projects"
  user_data                 = filebase64("apiinstall.sh")
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_api_project2.id]
  }
}

resource "aws_autoscaling_group" "AutoScaled_API_project2" {
  name                 = "AutoScaled_API_project2"
  launch_template {
    id      = aws_launch_template.EC2_template_project2.id
    version = "$Latest"
  }
  
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.pub-subnet.id]
  target_group_arns    = [aws_lb_target_group.lb-target-group-project2.arn]

  tag {
      key                 = "Name"
      value               = "PUB_API"
      propagate_at_launch = true
     }
}

resource "aws_elb" "elb-project2" {
  name               = "elb-project2"
  security_groups    = [aws_security_group.sg_api_project2.id]
  subnets            = [aws_subnet.pub-subnet.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_lb_target_group" "lb-target-group-project2" {
  name     = "lb-target-group-project2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-project2.id
}

resource "null_resource" "rename_PUB_API" {
  depends_on = [aws_autoscaling_group.AutoScaled_API_project2]
  provisioner "local-exec" {
    command = file("rename.txt")
  }
}
