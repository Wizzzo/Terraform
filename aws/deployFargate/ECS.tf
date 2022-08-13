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