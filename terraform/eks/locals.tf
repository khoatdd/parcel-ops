locals {
  parcel_vpc_id                                    = "vpc-xxxxxxxx"
  cluster_name                                     = "parcel-eks-prod"
  cluster_autoscaler_k8s_service_account_namespace = "kube-system"
  cluster_autoscaler_k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler"
}