<!-- BEGIN_TF_DOCS -->
# terraform-aws-cloudfront

This module manage the AWS Cloudfront distribution.

## Usage

### Basic

```hcl
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../..//."
}

#dependency "web_resources_bucket" {
#  config_path = ""
#
#  mock_outputs = {
#    id              = "cluster-1234567890"
#    name            = "developertown-ecs"
#    security_groups = ["sg-1234567890"]
#  }
#}

inputs = {
  enabled = true

  region      = "us-east-2"
  environment = "test"

  origins = [{
    id          = "google_origin_1234"
    domain_name = "google.com"
    s3_origin = {
      enabled = false
    }
    cache = {
      default = true
    }
  }]

  tags = {
    "Company" = "DeveloperTown"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.36.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.sub_folder_routing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_identity.oai](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_cloudfront_response_headers_policy.web_security_headers_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_route53_record.apex_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket_policy.web_resources_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_iam_policy_document.web_resources_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_origins"></a> [origins](#input\_origins) | The origin to use for the cloudfront distribution | <pre>list(object({<br>    id          = string<br>    domain_name = string<br>    http_port   = optional(number, 80)<br>    https_port  = optional(number, 443)<br>    cache = optional(object({<br>      default      = optional(bool, false)<br>      path_pattern = optional(string, "")<br>      min_ttl      = optional(number, 0)<br>      default_ttl  = optional(number, 3600)<br>      max_ttl      = optional(number, 86400)<br>      }), {<br>      default      = false<br>      path_pattern = ""<br>      min_ttl      = 0<br>      default_ttl  = 3600<br>      max_ttl      = 86400<br>    })<br>    s3_origin = optional(object({<br>      enabled            = optional(bool, false)<br>      bucket_id          = optional(string, "")<br>      bucket_domain_name = optional(string, "")<br>      bucket_arn         = optional(string, "")<br>      }), {<br>      enabled            = false<br>      bucket_id          = ""<br>      bucket_domain_name = ""<br>      bucket_arn         = ""<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The acm viewer certificate arn to use in the cloudfront distribution | `string` | `""` | no |
| <a name="input_apex_alias"></a> [apex\_alias](#input\_apex\_alias) | The DNS zone to use for SSL certificates, and Route 53 records | `bool` | `false` | no |
| <a name="input_apex_dns_zone_id"></a> [apex\_dns\_zone\_id](#input\_apex\_dns\_zone\_id) | The route 53 zone id to associate a route 53 A record with | `string` | `""` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_logs_bucket_domain_name"></a> [logs\_bucket\_domain\_name](#input\_logs\_bucket\_domain\_name) | Name to be used for the web resources bucket | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br>This is the only ID element not also included as a `tag`.<br>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `"ecs-cluster"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which the resources will be created | `string` | `null` | no |
| <a name="input_route53_domain_names"></a> [route53\_domain\_names](#input\_route53\_domain\_names) | The route 53 domain names | `list(string)` | `[]` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | The route 53 zone id to associate a route 53 A record with | `string` | `""` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Suffix to be added to the name of each resource | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'Unit': 'XYZ'}`).<br>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_viewer_certificate"></a> [viewer\_certificate](#input\_viewer\_certificate) | The SSL configuration for this distribution | `any` | <pre>{<br>  "cloudfront_default_certificate": true,<br>  "minimum_protocol_version": "TLSv1"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | n/a |
<!-- END_TF_DOCS -->