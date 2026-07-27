# Security Group for Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "websocket-chat-alb-sg"
  description = "Allow HTTP traffic to Application Load Balancer"
  vpc_id      = "vpc-05c1d2567df728cd0"

  ingress {
    description = "HTTP"
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
    Name = "websocket-chat-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "chat_alb" {
  name               = "websocket-chat-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    "subnet-007d453c603257f00",
    "subnet-000683113d4d1c2a1"
  ]

  tags = {
    Name = "websocket-chat-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "chat_tg" {
  name     = "websocket-chat-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-05c1d2567df728cd0"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "websocket-chat-tg"
  }
}

# Register Terraform EC2 with Target Group
resource "aws_lb_target_group_attachment" "chat_server" {
  target_group_arn = aws_lb_target_group.chat_tg.arn
  target_id        = aws_instance.chat_server.id
  port             = 80
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.chat_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_tg.arn
  }
}