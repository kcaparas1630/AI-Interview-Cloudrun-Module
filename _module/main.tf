# Loop through and create multiple Cloud Run services
resource "google_cloud_run_v2_service" "services" {
  for_each            = { for service in var.cloud_run_services : service.service_name => service }
  project             = var.project_id
  name                = each.value.service_name
  location            = var.region
  deletion_protection = try(each.value.deletion_protection, false)
  ingress             = try(each.value.ingress, "INGRESS_TRAFFIC_ALL")

  template {
    execution_environment = try(each.value.execution_environment, "EXECUTION_ENVIRONMENT_GEN2")
    service_account       = each.value.service_account

    # Volumes
    dynamic "volumes" {
      for_each = try(each.value.volumes, [])
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
      for_each = each.value.containers
      content {
        name  = lookup(containers.value, "name", null)
        image = "${containers.value.image}:${lookup(containers.value, "tag", "latest")}"

        # Container Port
        ports {
          container_port = each.value.container_port
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
      min_instance_count = try(each.value.min_instance_count, 0)
      max_instance_count = try(each.value.max_instance_count, 10)
    }

    # VPC Access
    dynamic "vpc_access" {
      for_each = try(each.value.vpc_access, null) != null ? [each.value.vpc_access] : []
      content {
        connector = vpc_access.value.connector
        egress    = lookup(vpc_access.value, "egress", null)
      }
    }
    
  }

  labels      = try(each.value.labels, {})
  annotations = try(each.value.annotations, {})

}

# Domain Mappings
resource "google_cloud_run_domain_mapping" "domain_mappings" {
  for_each = {
    for mapping in flatten([
      for service in var.cloud_run_services : [
        for domain in try(service.custom_domains, []) : {
          service_name = service.service_name
          domain       = domain
          key          = "${service.service_name}-${domain}"
        }
      ]
    ]) : mapping.key => mapping
  }
  
  name     = each.value.domain
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.services[each.value.service_name].name
  }
}

# IAM Bindings
resource "google_cloud_run_v2_service_iam_binding" "service_iam_bindings" {
  for_each = {
    for binding in flatten([
      for service in var.cloud_run_services : [
        for idx, binding in try(service.iam_bindings, []) : {
          service_name = service.service_name
          role         = binding.role
          members      = binding.members
          key          = "${service.service_name}-${idx}"
        }
      ]
    ]) : binding.key => binding
  }
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.services[each.value.service_name].name
  role     = each.value.role
  members  = each.value.members
}
