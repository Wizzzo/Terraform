resource "aws_alb" "demoAppLB" {
  name               = "demoAppLB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demoAppLBSG.id]
  ip_address_type = "ipv4"
#   subnets            = [aws_subnet.demoAppSubnet1.id, aws_subnet.demoAppSubnet2.id]
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  subnet_mapping {
    subnet_id = aws_subnet.demoAppSubnet1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.demoAppSubnet2.id
  }

  tags = {
    name        = "Demo App Load Balancer"
    Environment = "demoApp"
  }
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
    port                = 80
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