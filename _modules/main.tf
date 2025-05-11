resource "google_cloud_run_v2_service" "service" {
  project             = var.project_id
  name                = var.service_name
  location            = var.region
  deletion_protection = var.deletion_protection
  ingress             = var.ingress

  template {
    execution_environment = var.execution_environment
    service_account       = var.service_account

    # Volumes
    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value.name

        dynamic "secret" {
          for_each = contains(keys(volumes.value), "secret") && volumes.value.secret != null ? [volumes.value.secret] : []
          content {
            secret       = secret.value.secret_name
            default_mode = lookup(secret.value, "default_mode", null)

            dynamic "items" {
              for_each = lookup(secret.value, "items", [])
              content {
                path    = items.value.path
                version = lookup(items.value, "version", "latest")
              }
            }
          }
        }
      }
    }

    # Containers
    dynamic "containers" {
      for_each = var.containers
      content {
        name  = lookup(containers.value, "name", null)
        # If the tag is "initial", use the default image, otherwise use the image and tag
        image = contains(keys(containers.value), "tag") && containers.value.tag == "initial" ? "gcr.io/cloudrun/hello" : "${containers.value.image}:${lookup(containers.value, "tag", "latest")}"

        # Container Port
        ports {
          container_port = var.container_port
        }

        # Environment Variables
        dynamic "env" {
          for_each = lookup(containers.value, "env_vars", [])
          content {
            name = env.value.name

            # If secret_name is defined, use a value_source block
            dynamic "value_source" {
              for_each = contains(keys(env.value), "secret_name") && env.value.secret_name != null ? [env.value] : []
              content {
                secret_key_ref {
                  secret  = value_source.value.secret_name
                  version = lookup(value_source.value, "secret_version", "latest")
                }
              }
            }

            # If it's not secret-backed, use a normal value
            value = (contains(keys(env.value), "secret_name") && env.value.secret_name != null) ? null : env.value.value
          }
        }

        # Resources (CPU/Memory)
        resources {
          limits = try(containers.value.resources.limits, {})
        }

        # Volume Mounts
        dynamic "volume_mounts" {
          for_each = lookup(containers.value, "volume_mounts", [])
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }
      }
    }

    # Scaling
    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    # VPC Access
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        connector = vpc_access.value.connector
        egress    = lookup(vpc_access.value, "egress", null)
      }
    }
  }

  labels      = var.labels
  annotations = var.annotations
}

# Domain Mappings
resource "google_cloud_run_domain_mapping" "domain_mappings" {
  for_each = toset(var.custom_domains)
  name     = each.value
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.service.name
  }
}

# IAM Bindings
resource "google_cloud_run_v2_service_iam_binding" "service_iam_bindings" {
  for_each = { for idx, binding in var.iam_bindings : idx => binding }
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = each.value.role
  members  = each.value.members
}
