resource "aws_security_group" "demoAppLBSG" {
  name        = "demoAppLBSG"
  description = "Allow 0.0.0.0/80 inbound traffic"
  vpc_id      = aws_vpc.demoAppVPC.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name        = "Demo App Security Group LB"
    Environment = "demoApp"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ECS-SG"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.demoAppVPC.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.demoAppLBSG.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name        = "Demo App Security Group ECS"
    Environment = "demoApp"
  }
}