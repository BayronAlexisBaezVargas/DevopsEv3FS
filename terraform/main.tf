variable "project_name" {
  type    = string
  default = "devows-project"
}

provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 1. VPC por Defecto y Subredes
# ==========================================
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "public_details" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

locals {
  supported_subnets = [
    for s in data.aws_subnet.public_details : s.id
    if s.availability_zone != "us-east-1e"
  ]
}

# ==========================================
# 2. Roles IAM y SSM (AWS Academy)
# ==========================================
# En AWS Academy no podemos crear roles, usamos LabRole
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Perfil de instancia para la BD en EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = data.aws_iam_role.lab_role.name
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/devows/jwt_secret"
  type  = "SecureString"
  value = "EstaEsUnaClaveSecretaMuyLargaParaAsegurarElTokenDeSanosYSalvos2026"
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/devows/db_password"
  type  = "SecureString"
  value = "adminpassword"
  lifecycle { ignore_changes = [value] }
}

# ==========================================
# 3. ECR Repositories
# ==========================================
locals {
  services = [
    "frontend",
    "api-gateway",
    "eurekaserver",
    "ms-coincidencias",
    "ms-comunidad",
    "ms-mascota",
    "ms-notificaciones",
    "ms-usuario"
  ]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.services)
  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# ==========================================
# 4. Base de Datos en EC2 (PostgreSQL, Redis, RabbitMQ)
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group para Base de Datos EC2"
  vpc_id      = data.aws_vpc.default.id

  # Permitir conexiones desde cualquier lugar dentro de la VPC (EKS Nodes)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_instance" "postgres_db" {
  ami           = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = "t3.small" # Subido a t3.small para aguantar Postgres+Redis+Rabbit
  subnet_id     = local.supported_subnets[0]
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOFUSERDATA
#!/bin/bash
systemctl start docker
systemctl enable docker

# PostgreSQL
docker run -d --name postgres-db --restart always \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=adminpassword \
  -e POSTGRES_DB=dnf_db \
  -p 5432:5432 postgres:15-alpine

# Redis
docker run -d --name redis-db --restart always -p 6379:6379 redis:alpine

# RabbitMQ
docker run -d --name rabbitmq-db --restart always -p 5672:5672 -p 15672:15672 rabbitmq:3-management
EOFUSERDATA

  tags = {
    Name = "${var.project_name}-db-server"
  }
}

# ==========================================
# 5. Cluster EKS (Kubernetes)
# ==========================================
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = local.supported_subnets
  }
}

# ==========================================
# 6. EKS Node Group (Nodos de Trabajo)
# ==========================================
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = local.supported_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.main
  ]
}

# ==========================================
# 7. Outputs
# ==========================================
output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "db_server_private_ip" {
  value = aws_instance.postgres_db.private_ip
}
