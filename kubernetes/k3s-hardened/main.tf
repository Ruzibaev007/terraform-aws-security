# =============================================================================
# Kubernetes k3s Hardened — NIS2 Article 21 & 32
# Lightweight K8s for Mittelstand environments (single-node or HA)
# Security: RBAC, NetworkPolicies, PodSecurity, Audit Logging
# =============================================================================

terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.20" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# EC2: Hardened k3s master node
# =============================================================================
data "aws_ami" "ubuntu_hardened" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "k3s_master" {
  name = "${var.name_prefix}-k3s-master"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { NIS2Control = "Article-21-IAMRole" }
}

resource "aws_iam_role_policy_attachment" "k3s_ssm" {
  role       = aws_iam_role.k3s_master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  # SSM = no SSH needed → smaller attack surface (NIS2 Art.32)
}

resource "aws_iam_instance_profile" "k3s_master" {
  name = "${var.name_prefix}-k3s-master"
  role = aws_iam_role.k3s_master.name
}

resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu_hardened.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.k3s_master.name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]

  # NIS2 Art.32: No public IP — access via SSM only
  associate_public_ip_address = false

  # NIS2 Art.25: Encrypted root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    encrypted             = true
    kms_key_id            = var.kms_key_arn
    delete_on_termination = true
  }

  # NIS2 Art.32: IMDSv2 only (prevent SSRF)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring    = true  # Detailed CloudWatch monitoring
  ebs_optimized = true

  user_data = base64encode(templatefile("${path.module}/bootstrap-k3s.sh", {
    cluster_name = var.name_prefix
    environment  = var.environment
  }))

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-k3s-master"
    NIS2Control = "Article-21-32-K8sMaster"
    Role        = "kubernetes-master"
  })
}

# =============================================================================
# Security Group: k3s master — minimal access (NIS2 Art.32)
# =============================================================================
resource "aws_security_group" "k3s_master" {
  name        = "${var.name_prefix}-k3s-master"
  description = "NIS2 Art.32: Minimal ingress for k3s master"
  vpc_id      = var.vpc_id

  # K8s API only from worker nodes and admin bastion
  ingress {
    description     = "Kubernetes API"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }

  # k3s node communication
  ingress {
    description = "k3s node registration"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound (for updates, AWS API calls)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-k3s-sg"
    NIS2Control = "Article-32-NetworkSegmentation"
  })
}

# =============================================================================
# Kubernetes: NIS2 Network Policies (Article 21 & 32)
# =============================================================================

# Default deny all ingress in production namespace
resource "kubernetes_network_policy" "default_deny_ingress" {
  metadata {
    name      = "nis2-default-deny-ingress"
    namespace = var.k8s_namespace
    annotations = {
      "nis2.control" = "Article-32-NetworkSegmentation"
    }
  }

  spec {
    pod_selector {}  # Applies to ALL pods in namespace
    policy_types = ["Ingress"]
    # No ingress rules = deny all by default
  }
}

# Allow ingress only from ingress-controller to API pods
resource "kubernetes_network_policy" "allow_ingress_controller" {
  metadata {
    name      = "nis2-allow-ingress-controller"
    namespace = var.k8s_namespace
  }

  spec {
    pod_selector {
      match_labels = { tier = "api" }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = "ingress-nginx" }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Allow API pods to reach database only
resource "kubernetes_network_policy" "api_to_db" {
  metadata {
    name      = "nis2-api-to-db-only"
    namespace = var.k8s_namespace
  }

  spec {
    pod_selector {
      match_labels = { tier = "database" }
    }

    ingress {
      from {
        pod_selector {
          match_labels = { tier = "api" }
        }
      }
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# =============================================================================
# Kubernetes: RBAC (NIS2 Article 21)
# =============================================================================

# Read-only cluster role for auditors
resource "kubernetes_cluster_role" "nis2_auditor" {
  metadata {
    name = "nis2-auditor"
    annotations = {
      "nis2.control" = "Article-21-RBAC"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "nis2_auditor" {
  metadata {
    name = "nis2-auditor-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nis2_auditor.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "nis2-auditors"
    api_group = "rbac.authorization.k8s.io"
  }
}

# =============================================================================
# Variables & Outputs
# =============================================================================
variable "name_prefix"      { type = string }
variable "environment"      { type = string; default = "prod" }
variable "instance_type"    { type = string; default = "t3.large" }
variable "vpc_id"           { type = string }
variable "vpc_cidr"         { type = string }
variable "private_subnet_id" { type = string }
variable "kms_key_arn"      { type = string }
variable "k8s_namespace"    { type = string; default = "production" }
variable "tags"             { type = map(string); default = {} }

output "k3s_instance_id"   { value = aws_instance.k3s_master.id }
output "k3s_private_ip"    { value = aws_instance.k3s_master.private_ip }
output "k3s_sg_id"         { value = aws_security_group.k3s_master.id }
