variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

# Added Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Added Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Added Route Table Association
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
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

# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "ecs-microservice-cluster"
}

# --- IAM Role for ECS Task ---
#  are going to create an IAM role for the ECS task execution role. AAA
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole_microservice"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


#  this role GOES TO AAA
# CloudWatch Policy
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# this role GOES TO AAA
# ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#  this role GOES TO AAA
# ECR Policy Attachment-ARE CONNECTED AS A ROLE
resource "aws_iam_role_policy_attachment" "ecs_task_ecr_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_ecr_policy.arn
}

# Updated ECR Policy-ARECONNECTED AS  A POLICY
resource "aws_iam_policy" "ecs_task_ecr_policy" {
  name        = "ecsTaskECRPolicy"
  description = "Allow ECS task to access ECR"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family                   = "ecs-microservice-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "postgres"
      image = "767397930920.dkr.ecr.us-east-1.amazonaws.com/ger-16-todoapp:latest"
      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -U todo_user -d tododb"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      cpu   = 128
      memory = 512
      environment = [
        { name = "POSTGRES_USER", value = "todo_user" },
        { name = "POSTGRES_PASSWORD", value = "secure_password" },
        { name = "POSTGRES_DB", value = "tododb" }
      ]
      portMappings = [
        { containerPort = 5432, hostPort = 5432 }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/postgres"
          awslogs-region        = var.region
          awslogs-stream-prefix = "postgres"
        }
      }
    },
    {
      name  = "backend"
      image = "767397930920.dkr.ecr.us-east-1.amazonaws.com/ger-16-todoapp:backend-223"
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/todos || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
      dependsOn = [
        {
          containerName = "postgres"
          condition     = "HEALTHY"
        }
      ]
      cpu   = 128
      memory = 512
      environment = [
        { name = "DB_USER", value = "todo_user" },
        { name = "DB_PASSWORD", value = "secure_password" },
        { name = "DB_HOST", value = "postgres" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = "tododb" },
        { name = "SERVER_PORT", value = "5000" },
        { name = "HOST", value = "backend" },
      ]
      portMappings = [
        { containerPort = 5000, hostPort = 5000 }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/backend"
          awslogs-region        = var.region
          awslogs-stream-prefix = "backend"
        }
      }
    },
    {
      name  = "frontend"
      image = "767397930920.dkr.ecr.us-east-1.amazonaws.com/ger-16-todoapp:frontend-222"
      cpu   = 512
      memory = 512
      environment = [
        {
          name  = "REACT_APP_BASE_URL"
          value = "http://backend:5000/"  
        }
      ]
      portMappings = [
        { containerPort = 3000, hostPort = 3000 }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/frontend"
          awslogs-region        = var.region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

# --- ECS Service --- 
resource "aws_ecs_service" "app" {
  name            = "ecs-microservice-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  launch_type = "FARGATE"
}


# Added CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = toset(["postgres", "backend", "frontend"])
  name     = "/ecs/${each.key}"
}