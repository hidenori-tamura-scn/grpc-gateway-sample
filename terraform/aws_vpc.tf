/*
VPC
*/
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "demo_vpc"
  }
}

/*
サブネット
*/
//サブネット（パブリック a）
resource "aws_subnet" "demo_public_subnet_a" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.50.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo_public_subnet_a"
  }
}

//サブネット（プライベート a）
resource "aws_subnet" "demo_private_subnet_a" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.50.2.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "demo_private_subnet_a"
  }
}

//サブネット（パブリック c）
resource "aws_subnet" "demo_public_subnet_c" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.50.3.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo_public_subnet_c"
  }
}

//サブネット（プライベート c）
resource "aws_subnet" "demo_private_subnet_c" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.50.4.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "demo_private_subnet_c"
  }
}

/*
インターネットゲートウェイ
*/
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = {
    Name = "demo_igw"
  }
}

/*
ルートテーブル
*/
//ルートテーブル(パブリック)
resource "aws_route_table" "demo_public_rtb" {
  vpc_id = aws_vpc.demo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }
  tags = {
    Name = "demo_public_rtb"
  }
}

//ルートテーブル(プライベート)
resource "aws_route_table" "demo_private_rtb" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = {
    Name = "demo_private_rtb"
  }
}

//サブネットとルートテーブルの紐付け
//パブリック
resource "aws_route_table_association" "demo_rt_assoc_public_a" {
  subnet_id      = aws_subnet.demo_public_subnet_a.id
  route_table_id = aws_route_table.demo_public_rtb.id
}
resource "aws_route_table_association" "demo_rt_assoc_public_c" {
  subnet_id      = aws_subnet.demo_public_subnet_c.id
  route_table_id = aws_route_table.demo_public_rtb.id
}
//プライベート
resource "aws_route_table_association" "demo_rt_assoc_private_a" {
  subnet_id      = aws_subnet.demo_private_subnet_a.id
  route_table_id = aws_route_table.demo_private_rtb.id
}
resource "aws_route_table_association" "demo_rt_assoc_private_c" {
  subnet_id      = aws_subnet.demo_private_subnet_c.id
  route_table_id = aws_route_table.demo_private_rtb.id
}

/*
セキュリティグループ
*/

// default（暫定）
resource "aws_security_group" "demo_default_sg" {
  name   = "demo_default_sg"
  vpc_id = aws_vpc.demo_vpc.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.demo_container_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


//ec2
resource "aws_security_group" "demo_ec2_sg" {
  name   = "demo_ec2_sg"
  vpc_id = aws_vpc.demo_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# //db
# resource "aws_security_group" "demo_db_sg" {
#   name   = "demo_db_sg"
#   vpc_id = aws_vpc.demo_vpc.id
#   ingress {
#     from_port   = 1433
#     to_port     = 1433
#     protocol    = "tcp"
#     cidr_blocks = ["10.50.0.0/16"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

//alb
resource "aws_security_group" "demo_alb_sg" {
  name   = "demo_alb_sg"
  vpc_id = aws_vpc.demo_vpc.id
  ingress {
    from_port   = 15000
    to_port     = 15000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//container
resource "aws_security_group" "demo_container_sg" {
  name   = "demo_container_sg"
  vpc_id = aws_vpc.demo_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//privatelink
resource "aws_security_group" "demo_privatelink_sg" {
  name   = "demo_privatelink_sg"
  vpc_id = aws_vpc.demo_vpc.id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.demo_container_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
VPCエンドポイント
*/
//ecr_api(ECS-ECR接続に利用)
resource "aws_vpc_endpoint" "demo_privatelink_ecr_api" {
  vpc_id            = aws_vpc.demo_vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.demo_privatelink_sg.id
  ]
  tags = {
    Name = "demo_privatelink_ecr_api"
  }
}

//ecr_dkr(ECS-ECR接続に利用)
resource "aws_vpc_endpoint" "demo_privatelink_ecr_dkr" {
  vpc_id            = aws_vpc.demo_vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.demo_privatelink_sg.id
  ]
  tags = {
    Name = "demo_privatelink_ecr_dkr"
  }
}

//logs(ECS-CloudWatch logs接続に利用)
resource "aws_vpc_endpoint" "demo_privatelink_logs" {
  vpc_id            = aws_vpc.demo_vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.demo_privatelink_sg.id
  ]
  tags = {
    Name = "demo_privatelink_logs"
  }
}

# //S3(ECS-S3接続に利用)
# resource "aws_vpc_endpoint" "demo_privatelink_s3" {
#   vpc_id       = aws_vpc.demo_vpc.id
#   service_name = "com.amazonaws.ap-northeast-1.s3"
#   policy       = <<POLICY
#     {
#         "Statement": [
#             {
#                 "Action": "*",
#                 "Effect": "Allow",
#                 "Resource": "*",
#                 "Principal": "*"
#             }
#         ]
#     }
#     POLICY
#   tags = {
#     Name = "demo_privatelink_s3"
#   }
# }

# resource "aws_vpc_endpoint_route_table_association" "demo_privatelink_s3_route_table_assoc" {
#   vpc_endpoint_id = aws_vpc_endpoint.demo_privatelink_s3.id
#   route_table_id  = aws_route_table.demo_private_rtb.id
# }

// DNS
resource "aws_service_discovery_private_dns_namespace" "demo_internal" {
  name        = "demo.internal"
  description = "demo"
  vpc         = aws_vpc.demo_vpc.id
}

resource "aws_service_discovery_service" "demo_api" {
  name = "demo-api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.demo_internal.id

    dns_records {
      ttl  = 3600
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}