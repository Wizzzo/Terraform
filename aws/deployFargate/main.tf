provider "aws" {
  region = "eu-central-1"
}

resource "aws_alb_target_group" "demoAppTargetGroup" {
  name        = "demoAppTargetGroup"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.demoAppVPC.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
    path                = "/"
    interval            = 30
  }
}

resource "aws_alb_listener" "demoAppListener" {
  load_balancer_arn = aws_alb.demoAppLB.id
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
  #enable above 2 if you are using HTTPS listner and change protocal from HTTPS to HTTPS
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.demoAppTargetGroup.arn
  }
}

resource "aws_alb" "demoAppLB" {
  name               = "demoAppLB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demoAppLBSG.id]
  subnets            = [aws_subnet.demoAppSubnet1.id, aws_subnet.demoAppSubnet2.id]
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    name        = "Demo App Load Balancer"
    Environment = "demoApp"
  }
}

resource "aws_vpc" "demoAppVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name        = "Demo App VPC"
    Environment = "demoApp"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demoAppVPC.id

  tags = {
    Name        = "Demo App Internet Gateway"
    Environment = "demoApp"
  }
}

resource "aws_subnet" "demoAppSubnet1" {
  vpc_id            = aws_vpc.demoAppVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name        = "Demo App Subnet 1"
    Environment = "demoApp"
  }
}

resource "aws_subnet" "demoAppSubnet2" {
  vpc_id            = aws_vpc.demoAppVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name        = "Demo App Subnet 2"
    Environment = "demoApp"
  }
}

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

resource "aws_ecs_task_definition" "demoAppTaskDefinition" {
  family                   = "demoAppTaskDefinition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "DemoAppContainer"
      image     = "public.ecr.aws/e6a9b3x8/tutorial_docker_app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  # volume {
  #   name      = "service-storage"
  #   host_path = "/ecs/service-storage"
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
}

resource "aws_ecs_cluster" "demoAppCluster" {
  name = "demoAppCluster"


  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "Demo App Cluster"
    Environment = "demoApp"
  }
}

resource "aws_ecs_service" "demoAppService" {
  name            = "demoAppService"
  cluster         = aws_ecs_cluster.demoAppCluster.id
  task_definition = aws_ecs_task_definition.demoAppTaskDefinition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets           = [aws_subnet.demoAppSubnet1.id, aws_subnet.demoAppSubnet2.id]
    security_groups   = [aws_security_group.ecs_sg.id]
    assign_public_ip  = true
  }
  
  load_balancer {
    target_group_arn  = aws_alb_target_group.demoAppTargetGroup.arn
    container_name    = "DemoAppContainer"
    container_port    = 80
  }
}