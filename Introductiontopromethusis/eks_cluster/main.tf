# Terraform: EKS Cluster in us-east-1 with default subnets

provider "aws" {
  region = "us-east-1"
}

#######################
# 1. IAM Roles
#######################

# The roles already exist, so we use data sources instead

data "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"
}

data "aws_iam_role" "eks_node_role" {
  name = "eksNodeRole"
}

##########################
# 2. Get Default Subnets
##########################

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

######################
# 3. EKS Cluster
######################

resource "aws_eks_cluster" "eks" {
  name     = "observability"
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "observability-ng-private"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t3.medium"]
  disk_size      = 20
}

#########################
# 4. Outputs
#########################

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.eks.name}"
}
