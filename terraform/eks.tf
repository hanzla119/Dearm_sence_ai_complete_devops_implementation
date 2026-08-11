module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # Networking
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  control_plane_subnet_ids        = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Grants the creator admin access to the cluster automatically
  enable_cluster_creator_admin_permissions = true

  # Cost-Optimized Managed Node Group in Private Subnets (Fast & Stable)
  eks_managed_node_groups = {
    cost_optimized_nodes = {
      name           = "dermasense-spot-nodes"
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"
      platform       = "al2023"                   # Required for Kubernetes 1.30+
      ami_type       = "AL2023_x86_64_STANDARD"
      subnet_ids     = module.vpc.private_subnets

      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes

      disk_size = 20

      labels = {
        Environment = "production"
        Workload    = "dermasense-ai"
      }
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}


