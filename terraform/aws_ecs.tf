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
# resource "aws_ecs_task_definition" "demo_task_definition" {
#   family = "demo-task"
#   cpu    = 512
#   memory = 1024

#   container_definitions = jsonencode(
#     [
#       {
#         name      = "demo-server-container"
#         image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-server:latest"
#         cpu       = 256
#         memory    = 512
#         essential = true
#         portMappings = [
#           {
#             containerPort = 5001
#             hostPort      = 5001
#           }
#         ]
#         logConfiguration = {
#           logDriver = "awslogs"
#           options = {
#             awslogs-group         = "/ecs/demo-task"
#             awslogs-region        = "ap-northeast-1"
#             awslogs-stream-prefix = "ecs"
#           }
#         }
#       },
#       {
#         name      = "demo-gateway-container"
#         image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-gateway:latest"
#         cpu       = 256
#         memory    = 512
#         essential = true
#         portMappings = [
#           {
#             containerPort = 15000
#             hostPort      = 15000
#           }
#         ]
#         logConfiguration = {
#           logDriver = "awslogs"
#           options = {
#             awslogs-group         = "/ecs/demo-task"
#             awslogs-region        = "ap-northeast-1"
#             awslogs-stream-prefix = "ecs"
#           }
#         }
#       },
#     ]
#   )
#   network_mode = "awsvpc"
#   requires_compatibilities = [
#     "FARGATE",
#   ]
#   execution_role_arn = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
# }

resource "aws_ecs_task_definition" "demo_grpc_server_task_definition" {
  family = "demo-grpc-server-task"
  cpu    = 256
  memory = 512

  container_definitions = jsonencode(
    [
      {
        name      = "demo-grpc-server-container"
        image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-server:latest"
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
            awslogs-group         = "/ecs/demo-grpc-server"
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
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_task_definition" "demo_grpc_gateway_task_definition" {
  family = "demo-grpc-gateway-task"
  cpu    = 256
  memory = 512

  container_definitions = jsonencode(
    [
      {
        name      = "demo-grpc-gateway-container"
        image     = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/demo-grpc-gateway:latest"
        essential = true
        portMappings = [
          {
            containerPort = 15000
            hostPort      = 15000
          }
        ]
        environment = [
          { "name" : "GRPC_GATEWAY_ENDPOINT", "value" : "demo-api.demo.internal:5001" }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/demo-grpc-gateway"
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
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
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
# resource "aws_ecs_service" "demo_ecs_service" {
#   name            = "demo-service"
#   cluster         = aws_ecs_cluster.demo_ecs_cluster.name
#   task_definition = aws_ecs_task_definition.demo_task_definition.arn
#   launch_type     = "FARGATE"
#   //コレ指定しないとLoadBalancer指定のところで落ちる
#   depends_on = [aws_lb_target_group.demo_targetgroup]
#   network_configuration {
#     subnets         = [aws_subnet.demo_private_subnet_a.id]
#     security_groups = [aws_security_group.demo_container_sg.id]
#   }

#   //ECSタスクの起動数
#   desired_count = 0

#   load_balancer {
#     target_group_arn = aws_lb_target_group.demo_targetgroup.arn
#     container_name   = "demo-gateway-container"
#     container_port   = 15000
#   }
# }

resource "aws_ecs_service" "demo_grpc_server_service" {
  name            = "demo-grpc-server-service"
  cluster         = aws_ecs_cluster.demo_ecs_cluster.name
  task_definition = aws_ecs_task_definition.demo_grpc_server_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.demo_public_subnet_a.id, aws_subnet.demo_public_subnet_c.id]
    security_groups = [aws_security_group.demo_default_sg.id,
      aws_security_group.demo_privatelink_sg.id,
      aws_security_group.demo_alb_sg.id,
      aws_security_group.demo_ec2_sg.id,
      aws_security_group.demo_container_sg.id,
    aws_security_group.demo_privatelink_sg.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.demo_api.arn
  }
}

resource "aws_ecs_service" "demo_grpc_gateway_service" {
  name                              = "demo-grpc-gateway-service"
  cluster                           = aws_ecs_cluster.demo_ecs_cluster.name
  task_definition                   = aws_ecs_task_definition.demo_grpc_gateway_task_definition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  depends_on                        = [aws_lb_target_group.demo_targetgroup] //コレ指定しないとLoadBalancer指定のところで落ちる
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.demo_public_subnet_a.id, aws_subnet.demo_public_subnet_c.id]
    security_groups = [aws_security_group.demo_default_sg.id,
      aws_security_group.demo_privatelink_sg.id,
      aws_security_group.demo_alb_sg.id,
      aws_security_group.demo_ec2_sg.id,
      aws_security_group.demo_container_sg.id,
    aws_security_group.demo_privatelink_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.demo_targetgroup.arn
    container_name   = "demo-grpc-gateway-container"
    container_port   = 15000
  }
}