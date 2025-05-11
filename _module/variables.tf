variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
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
