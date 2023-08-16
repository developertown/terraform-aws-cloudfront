variable "logs_bucket_domain_name" {
  description = "Name to be used for the web resources bucket"
  type        = string
  default     = ""
}

variable "route53_domain_names" {
  description = "The route 53 domain names"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "The route 53 zone id to associate a route 53 A record with"
  type        = string
  default     = ""
}

variable "apex_dns_zone_id" {
  description = "The route 53 zone id to associate a route 53 A record with"
  type        = string
  default     = ""
}

variable "apex_alias" {
  description = "The DNS zone to use for SSL certificates, and Route 53 records"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "The acm viewer certificate arn to use in the cloudfront distribution"
  type        = string
  default     = ""
}

variable "origins" {
  description = "The origin to use for the cloudfront distribution"

  type = list(object({
    id          = string
    domain_name = string
    http_port   = optional(number, 80)
    https_port  = optional(number, 443)
    cache = optional(object({
      default      = optional(bool, false)
      path_pattern = optional(string, "")
      min_ttl      = optional(number, 0)
      default_ttl  = optional(number, 3600)
      max_ttl      = optional(number, 86400)
      }), {
      default      = false
      path_pattern = ""
      min_ttl      = 0
      default_ttl  = 3600
      max_ttl      = 86400
    })
    s3_origin = optional(object({
      enabled            = optional(bool, false)
      bucket_id          = optional(string, "")
      bucket_domain_name = optional(string, "")
      bucket_arn         = optional(string, "")
      }), {
      enabled            = false
      bucket_id          = ""
      bucket_domain_name = ""
      bucket_arn         = ""
    })
  }))
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution"
  type        = any
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
}