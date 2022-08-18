provider "aws" {
  region = "eu-west-1"
}

resource "aws_apprunner_service" "demoAppRunnerService" {
  service_name = "demoAppRunnerService"

  source_configuration {
    image_repository {
      image_configuration {
        port = "80"
      }
      image_identifier      = "public.ecr.aws/e6a9b3x8/tutorial_docker_app:latest"
      image_repository_type = "ECR_PUBLIC"
    }
    auto_deployments_enabled = false
  }

  tags = {
    Name = "Demo App Runner Service"
  }
}