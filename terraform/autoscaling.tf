# Launch Template for Auto Scaling instances
resource "aws_launch_template" "chat_lt" {
  name_prefix   = "websocket-chat-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.chat_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-v2 git

    systemctl enable docker
    systemctl start docker

    cd /home/ubuntu

    git clone https://github.com/namitagrawal2001/websocket-devops-assignment.git
    cd websocket-devops-assignment

    docker compose up -d --build
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "websocket-chat-asg"
      Project = "Real-Time-WebSocket-Chat"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "chat_asg" {
  name = "websocket-chat-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  vpc_zone_identifier = [
    "subnet-007d453c603257f00",
    "subnet-000683113d4d1c2a1"
  ]

  target_group_arns = [
    aws_lb_target_group.chat_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.chat_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "websocket-chat-asg"
    propagate_at_launch = true
  }
}

# Target Tracking Auto Scaling Policy
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "websocket-chat-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.chat_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}