
output "eks_cluster_id" {
  description = "ID of the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version for the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "eks_node_group_arn" {
  description = "ARN of the EKS Node Group"
  value       = aws_eks_node_group.eks_nodes.arn
}

output "eks_node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.eks_nodes.status
}
