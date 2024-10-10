# Example of variables you can define
variable "region" {
  default = "us-east-1"
}

variable "s3_bucket_name" {
  default = "my-fruit-shop-static-site"
}


variable "env" {
  description = "The environment (e.g., dev, prod) for the infrastructure"
  type        = string
  default     = "prod" # You can set the default to whatever environment you are working in
}

# Declare the `aliases` variable
variable "aliases" {
  description = "Custom domain aliases for the CloudFront distribution (optional)."
  type        = list(string)
  default     = [] # No aliases by default, set to your custom domain if needed.
}

# Declare the `web_acl_id` variable
variable "web_acl_id" {
  description = "The ID of the Web ACL associated with CloudFront (optional)."
  type        = string
  default     = "" # Leave empty if not using AWS WAF.
}

# Declare the `acm_certificate_arn` variable
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for CloudFront HTTPS."
  type        = string
  default     = "" # Set to your ACM certificate ARN if using HTTPS.
}
