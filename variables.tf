variable "bucket_name" {
  description = "Name of the S3 bucket for storing static files"
}

variable "logs_bucket" {
  description = "Name of the S3 bucket for storing CloudFront access logs (leave empty to use default name)"
  default = null
}

variable "cloudfront_enabled" {
  description = "Indicates whether to enable to CloudFront distribution"
  default = false
}

variable "default_root_object" {
  description = "File to return for request on root URL"
  default = "index.html"
}

variable "error_page" {
  description = "File to return for 404 errors"
  default = "filenotfound.html"
}

variable "price_class" {
  description = "CloudFront distribution price class"
  default = "PriceClass_100"
  validation {
    condition = contains(["PriceClass_All", "PriceClass_100", "PriceClass_200"], var.price_class)
    error_message = "Invalid price class."
  }
}

variable "default_ttl" {
  description = "Default TTL for CloudFront caching"
  default = 86400
  validation {
    condition = var.default_ttl > 0
    error_message = "TTL must be greater than zero."
  }
}

variable "domain" {
  description = "Site domain"
}

variable "aliases" {
  description = "Alias FQDNs for the CloudFront distribution"
  type = list(string)
  default = ["www"]
}
