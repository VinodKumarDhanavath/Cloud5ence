variable "domain_name" {
  description = "Your domain"
  type        = string
  default     = "cloud5ence.com"
}

variable "aws_region" {
  description = "Primary AWS region (closest to Ottawa)"
  type        = string
  default     = "ca-central-1"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "cloud5ence-website"
    Owner       = "Vinod Kumar Dhanavath"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
