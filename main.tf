###############################################################
# Khối cấu hình provider AWS
# Chỉ định vùng triển khai dựa vào biến 'region'
###############################################################
provider "aws" {
  region = var.region
}

###############################################################
# Tạo VPC riêng cho cụm EKS
# CIDR block: 10.0.0.0/16
###############################################################
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks-vpc"
  }
}

###############################################################
# Tạo 2 subnet công khai cho VPC
# Mỗi subnet nằm ở một Availability Zone khác nhau
###############################################################
resource "aws_subnet" "eks_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

###############################################################
# Tạo Internet Gateway
###############################################################
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

# Tạo Route Table
resource "aws_route_table" "eks_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "eks-rt"
  }
}

# Gán Route Table cho Subnets
resource "aws_route_table_association" "eks_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_rt.id
}

###############################################################
# Tạo Security Group cho cụm EKS
# Cho phép truy cập cổng 443 từ mọi nơi (ingress)
# Cho phép tất cả outbound traffic (egress)
###############################################################
# Security Group cho EKS Cluster
resource "aws_security_group" "eks_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "eks-cluster-sg"
  }
}

# Security Group cho Node Group (cho phép giao tiếp từ cluster)
resource "aws_security_group" "node_sg" {
  name        = "eks-node-sg"
  description = "EKS node group security group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_sg.id] # Cho phép traffic từ cluster SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-sg"
  }
}

###############################################################
# Tạo cụm EKS
# Sử dụng các subnet và security group đã tạo ở trên
###############################################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn
  # role_arn = var.eks_role_arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"] # CloudWatch logging

  vpc_config {
    subnet_ids         = aws_subnet.eks_subnet[*].id
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

###############################################################
# Tạo node group cho cụm EKS
# Quy định số lượng node tối thiểu, tối đa và mong muốn
###############################################################
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  # node_role_arn  = var.node_role_arn
  subnet_ids     = aws_subnet.eks_subnet[*].id
  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  depends_on = [aws_eks_cluster.eks_cluster, aws_iam_role.node_role]
}
