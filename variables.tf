
variable "region" {
  description = "AWS region to deploy EKS"
  type        = string
  default     = "ap-southeast-1"
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# variable "eks_role_arn" {
#   description = "IAM role ARN for EKS cluster"
#   type        = string
#   # default     = "arn:aws:iam::998583535244:role/auto_eks_role "
# }

# variable "node_role_arn" {
#   description = "IAM role ARN for EKS node group"
#   type        = string
#   # default     = "arn:aws:iam::998583535244:role/auto_node_role"
# }
