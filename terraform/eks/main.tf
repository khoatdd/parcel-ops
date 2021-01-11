provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "parcel" {
  id = "${local.parcel_vpc_id}"
}

data "aws_subnet_ids" "dmz" {
  vpc_id = data.aws_vpc.parcel.id
  filter {
    name   = "tag:Name"
    values = ["*DMZ Subnet*"]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.parcel.id
  filter {
    name   = "tag:Name"
    values = ["*Public Subnet*"]
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "11.0.0"

  cluster_name = local.cluster_name
  subnets      = setunion(data.aws_subnet_ids.dmz.ids, data.aws_subnet_ids.public.ids)
  vpc_id       = data.aws_vpc.parcel.id
  enable_irsa  = true

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = false

  worker_groups_launch_template = [
    {
      name                    = "spot-1"
      subnets                 = data.aws_subnet_ids.dmz.ids
      ami_id                  = "ami-088e05a9da0f9443c"
      override_instance_types = ["m5.xlarge", "m5a.xlarge", "m5d.xlarge", "m5ad.xlarge"]
      on_demand_allocation_strategy            = null
      on_demand_base_capacity                  = "0"     
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "lowest-price"  
      protect_from_scale_in = true
      spot_instance_pools     = 4
      asg_min_size            = 1
      asg_max_size            = 10
      asg_desired_capacity    = 1
      asg_recreate_on_change  = false
      asg_force_delete        = true
      kubelet_extra_args      = "--node-labels=kubernetes.io/lifecycle=spot"
      public_ip               = false
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "true"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          "propagate_at_launch" = "true"
          "value"               = "owned"
        }
      ]
    },
    {
      name                    = "on-demand-1"
      subnets                 = data.aws_subnet_ids.dmz.ids
      ami_id                  = "ami-088e05a9da0f9443c"
      override_instance_types = ["m5.xlarge"]
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = "0"     
      on_demand_percentage_above_base_capacity = "100"
      protect_from_scale_in = true
      asg_min_size            = 1
      asg_max_size            = 5
      asg_desired_capacity    = 1
      asg_recreate_on_change  = false
      asg_force_delete        = true
      kubelet_extra_args      = "--node-labels=kubernetes.io/lifecycle=onDemand"
      public_ip               = false
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "true"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          "propagate_at_launch" = "true"
          "value"               = "owned"
        }
      ]
    },
  ]
  ### TODO - Map Jenkins or TeamCity Role 
  # map_roles = [
  #   {
  #     rolearn  = aws_iam_role.jenkins.arn
  #     username = "jenkins"
  #     groups   = ["system:masters"]
  #   },
  # ]
}