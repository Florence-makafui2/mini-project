variable "region" {
  type        = string
  default     = "us-east-1"
  description = "insfrastructure region"
}

variable "access_key" {
  type        = string
  sensitive     = "true"
  description = "access_key that belongs to IAM user"
}

variable "secret_key" {
  type        = string
  sensitive     = "true"
  description = "secret_key that belongs to IAM user"
}



