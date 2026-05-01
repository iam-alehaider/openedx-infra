
#==============================
# Node Security Group
#==============================

resource "aws_security_group" "nodes" {
  name        = "${local.name}-eks-nodes-sg"
  description = "EKS worker nodes security group"
  vpc_id      = var.vpc_id

  # Allow nodes to communicate with each other
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  # Allow control plane to reach kubelet API on nodes
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane to reach kubelet API on nodes"
  }

  # Allow control plane to reach NodePort services
  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane to reach NodePort services"
  }

  # Allow control plane HTTPS to nodes
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane HTTPS to nodes"
  }

# Only HTTPS inside VPC (via endpoints)
 egress {
   from_port   = 443
   to_port     = 443
   protocol    = "tcp"
   cidr_blocks = [var.vpc_cidr]
 }

# Allow internal communication
 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = [var.vpc_cidr]
 }  

  tags = merge(local.tags, { Name = "${local.name}-eks-nodes-sg" })
}

#==================================
# Node Group IAM Role + Policies
#===================================

resource "aws_iam_role" "nodes" {
  name = "${local.name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

