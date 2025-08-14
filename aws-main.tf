# AWS EKS Infrastructure Configuration

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "eks_vpc" {
  count = var.cloud_provider == "aws" ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "eks-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.eks_vpc[0].id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_subnet" "eks_public_subnet" {
  count = var.cloud_provider == "aws" ? 2 : 0

  vpc_id                  = aws_vpc.eks_vpc[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "eks-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "eks_private_subnet" {
  count = var.cloud_provider == "aws" ? 2 : 0

  vpc_id            = aws_vpc.eks_vpc[0].id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "eks-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_eip" "eks_nat_eip" {
  count = var.cloud_provider == "aws" ? 1 : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.eks_igw]

  tags = {
    Name = "eks-nat-eip"
  }
}

resource "aws_nat_gateway" "eks_nat" {
  count = var.cloud_provider == "aws" ? 1 : 0

  allocation_id = aws_eip.eks_nat_eip[0].id
  subnet_id     = aws_subnet.eks_public_subnet[0].id

  tags = {
    Name = "eks-nat-gateway"
  }

  depends_on = [aws_internet_gateway.eks_igw]
}

resource "aws_route_table" "eks_public_rt" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.eks_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw[0].id
  }

  tags = {
    Name = "eks-public-route-table"
  }
}

resource "aws_route_table" "eks_private_rt" {
  count = var.cloud_provider == "aws" ? 1 : 0

  vpc_id = aws_vpc.eks_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat[0].id
  }

  tags = {
    Name = "eks-private-route-table"
  }
}

resource "aws_route_table_association" "eks_public_rta" {
  count = var.cloud_provider == "aws" ? 2 : 0

  subnet_id      = aws_subnet.eks_public_subnet[count.index].id
  route_table_id = aws_route_table.eks_public_rt[0].id
}

resource "aws_route_table_association" "eks_private_rta" {
  count = var.cloud_provider == "aws" ? 2 : 0

  subnet_id      = aws_subnet.eks_private_subnet[count.index].id
  route_table_id = aws_route_table.eks_private_rt[0].id
}

resource "aws_security_group" "eks_cluster_sg" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "eks-cluster-sg"
  vpc_id      = aws_vpc.eks_vpc[0].id

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

resource "aws_security_group" "eks_node_sg" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name_prefix = "eks-node-sg"
  vpc_id      = aws_vpc.eks_vpc[0].id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg[0].id]
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

resource "aws_iam_role" "eks_cluster_role" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  count = var.cloud_provider == "aws" ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[0].name
}

resource "aws_iam_role" "eks_node_role" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  count = var.cloud_provider == "aws" ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  count = var.cloud_provider == "aws" ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  count = var.cloud_provider == "aws" ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role[0].name
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = concat(aws_subnet.eks_public_subnet[*].id, aws_subnet.eks_private_subnet[*].id)
    security_group_ids      = [aws_security_group.eks_cluster_sg[0].id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]

  tags = {
    Name = var.cluster_name
  }
}

# EKS Node Group
resource "aws_eks_node_group" "eks_nodes" {
  count = var.cloud_provider == "aws" ? 1 : 0

  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_role[0].arn
  subnet_ids      = aws_subnet.eks_private_subnet[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "eks-nodes"
  }
}
