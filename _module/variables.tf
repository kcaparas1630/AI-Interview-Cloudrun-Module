variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud Run services"
  type        = string
  default     = "us-central1"
}

variable "cloud_run_services" {
  description = "List of Cloud Run services to create"
  type = list(object({
    service_name          = string
    service_account       = string
    container_port        = number
    execution_environment = optional(string, "EXECUTION_ENVIRONMENT_GEN2")
    deletion_protection   = optional(bool, false)
    ingress               = optional(string, "INGRESS_TRAFFIC_ALL")
    
    containers = list(object({
      name      = optional(string)
      image     = string
      tag       = optional(string, "latest")
      env_vars  = optional(list(object({
        name           = string
        value          = optional(string)
        secret_name    = optional(string)
        secret_version = optional(string, "latest")
      })), [])
      resources = optional(object({
        limits = optional(map(string), {})
      }), null)
      volume_mounts = optional(list(object({
        name       = string
        mount_path = string
      })), [])
    }))
    
    volumes = optional(list(object({
      name = string
      secret = optional(object({
        secret_name  = string
        default_mode = optional(number)
        items = optional(list(object({
          path    = string
          version = optional(string, "latest")
        })), [])
      }))
    })), [])
    
    min_instance_count = optional(number, 0)
    max_instance_count = optional(number, 10)
    timeout_seconds    = optional(number, 300)
    cpu_throttling     = optional(bool)
    startup_cpu_boost  = optional(bool)
    
    vpc_access = optional(object({
      connector = string
      egress    = optional(string)
    }))
    
    custom_domains = optional(list(string), [])
    
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
    
    iam_bindings = optional(list(object({
      role    = string
      members = list(string)
    })), [])
  }))
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "containers" {
  description = "Optional list of container definitions."
  type = list(object({
    name          = optional(string)
    image         = string
    tag           = optional(string, "latest")
    env_vars = optional(list(object({
      name           = string
      value          = optional(string)
      secret_name     = optional(string)
      secret_version  = optional(string, "latest")
    })), [])
    resources = optional(object({
      limits = map(string)
    }))
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
}

variable "volumes" {
  description = "List of volumes to make available to containers"
  type = list(object({
    name = string
    secret = optional(object({
      secret_name  = string
      default_mode = optional(number)
      items        = optional(list(object({
        path    = string
        version = optional(string, "latest")
      })), [])
    }))
  }))
  default = []
}

variable "min_instance_count" {
  description = "Minimum number of instances for the service"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances for the service"
  type        = number
  default     = 100
}

variable "vpc_access" {
  description = "VPC Access configuration for the service"
  type = object({
    connector = string
    egress    = optional(string, "ALL_TRAFFIC")
  })
  default = null
}

variable "custom_domains" {
  description = "List of custom domains to map to the Cloud Run service"
  type        = list(string)
  default     = []
}

variable "iam_bindings" {
  description = "List of IAM bindings to attach to the service"
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}

variable "service_account" {
  description = "Service account email to associate with the service"
  type        = string
  default     = null
}

variable "execution_environment" {
  description = "Execution environment for the service"
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the service"
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Annotations to apply to the service"
  type        = map(string)
  default     = {}
}

variable "ingress" {
  description = "Ingress settings for the service"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "deletion_protection" {
  description = "Whether to prevent the service from being deleted"
  type        = bool
  default     = false
}

variable "container_port" {
  description = "Port number for the container"
  type        = number
  default     = 8080
}
