# //Repository(DockeイメージをPushする先)
# resource "aws_ecr_repository" "demo" {
#   name                 = "demo"
#   image_tag_mutability = "MUTABLE"
#   tags = {
#     "Name" = "demo"
#   }

#   encryption_configuration {
#     encryption_type = "AES256"
#   }

#   image_scanning_configuration {
#     scan_on_push = false
#   }
# }

//タスク定義
resource "aws_ecs_task_definition" "demo_task_definition" {
  family = "demo-task"
  cpu    = 512
  memory = 1024

  container_definitions = jsonencode(
    [
      {
        name      = "demo-server-container"
        image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-server" //動かないけどタスク定義は作れる
        cpu       = 256
        memory    = 512
        essential = true
        portMappings = [
          {
            containerPort = 5001
            hostPort      = 5001
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/demo-task"
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "ecs"
          }
        }
      },
      {
        name      = "demo-gateway-container"
        image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-gateway"
        cpu       = 256
        memory    = 512
        essential = true
        portMappings = [
          {
            containerPort = 15000
            hostPort      = 15000
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/demo-task"
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "ecs"
          }
        }
      },
    ]
  )
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
}

//クラスター
resource "aws_ecs_cluster" "demo_ecs_cluster" {
  name = "demo-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    "Name" = "demo_ecs_cluster"
  }
}

//サービス
resource "aws_ecs_service" "demo_ecs_service" {
  name            = "demo-service"
  cluster         = aws_ecs_cluster.demo_ecs_cluster.name
  task_definition = aws_ecs_task_definition.demo_task_definition.arn
  launch_type     = "FARGATE"
  //コレ指定しないとLoadBalancer指定のところで落ちる
  depends_on = [aws_lb_target_group.demo_targetgroup]
  network_configuration {
    subnets         = [aws_subnet.demo_private_subnet_a.id]
    security_groups = [aws_security_group.demo_container_sg.id]
  }

  //ECSタスクの起動数
  desired_count = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.demo_targetgroup.arn
    container_name   = "demo-gateway-container"
    container_port   = 15000
  }
}