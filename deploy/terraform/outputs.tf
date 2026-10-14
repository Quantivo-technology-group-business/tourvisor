output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint address"
  value       = aws_db_instance.mysql.address
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint address"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "s3_uploads_bucket" {
  description = "S3 bucket for Tourvisor file uploads"
  value       = aws_s3_bucket.uploads.bucket
}
