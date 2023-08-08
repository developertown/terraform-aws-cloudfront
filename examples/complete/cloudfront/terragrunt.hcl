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
