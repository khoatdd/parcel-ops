output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "dmz_subnets" {
  value = data.aws_subnet_ids.dmz.ids
}

output "public_subnets" {
  value = data.aws_subnet_ids.public.ids
}

output "eks_cluster_name" {
  value = local.cluster_name
}