/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "containers" {
  description = "Containers in name => attributes format."
  type = map(object({
    image      = string
    depends_on = optional(list(string))
    command    = optional(list(string))
    args       = optional(list(string))
    env        = optional(map(string))
    env_from_key = optional(map(object({
      secret  = string
      version = string
    })))
    liveness_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    ports = optional(map(object({
      container_port = optional(number)
      name           = optional(string)
    })))
    resources = optional(object({
      limits = optional(object({
        cpu    = string
        memory = string
      }))
      cpu_idle          = optional(bool)
      startup_cpu_boost = optional(bool)
    }))
    startup_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      tcp_socket = optional(object({
        port = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    volume_mounts = optional(map(string))
  }))
  default  = {}
  nullable = false
}

variable "create_job" {
  description = "Create Cloud Run Job instead of Service."
  type        = bool
  default     = false
}

variable "custom_audiences" {
  description = "Custom audiences for service."
  type        = list(string)
  default     = null
}

variable "deletion_protection" {
  description = "Deletion protection setting for this Cloud Run service."
  type        = string
  default     = null
}

variable "encryption_key" {
  description = "The full resource name of the Cloud KMS CryptoKey."
  type        = string
  default     = null
}

variable "eventarc_triggers" {
  description = "Event arc triggers for different sources."
  type = object({
    audit_log = optional(map(object({
      method  = string
      service = string
    })))
    pubsub = optional(map(string))
    storage = optional(map(object({
      bucket = string
      path   = optional(string)
    })))
    service_account_email  = optional(string)
    service_account_create = optional(bool, false)
  })
  default = {}
  validation {
    condition     = var.eventarc_triggers.audit_log == null || (var.eventarc_triggers.audit_log != null && (var.eventarc_triggers.service_account_email != null || var.eventarc_triggers.service_account_create))
    error_message = "When setting var.eventarc_triggers.audit_log provide either service_account_email or set service_account_create to true"
  }
}

variable "iam" {
  description = "IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iap_config" {
  description = "If present, turns on Identity-Aware Proxy (IAP) for the Cloud Run service."
  type = object({
    iam          = optional(list(string), [])
    iam_additive = optional(list(string), [])
  })
  default = null

  validation {
    condition = !(length(try(var.iap_config.iam, [])) > 0 && length(try(var.iap_config.iam_additive, [])) > 0)

    error_message = "Providing both 'iam' and 'iam_additive' in iap_config is not supported."
  }

  validation {
    condition     = var.iap_config == null || !var.create_job
    error_message = "IAP is only supported for Cloud Run services, not Cloud Run jobs. Set create_job to false when using iap_config."
  }

  validation {
    condition     = var.iap_config == null || var.launch_stage != "GA"
    error_message = "iap is currently not supported in GA. Set launch_stage to 'BETA' or lower."
  }
}

variable "ingress" {
  description = "Ingress settings."
  type        = string
  default     = null
  validation {
    condition = (
      var.ingress == null ? true : contains(
        ["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    )
    error_message = <<EOF
    Ingress should be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY,
    INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
    EOF
  }
}

variable "invoker_iam_disabled" {
  description = "Disables IAM permission check for run.routes.invoke for callers of this service."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "launch_stage" {
  description = "The launch stage as defined by Google Cloud Platform Launch Stages."
  type        = string
  default     = null
  validation {
    condition = (
      var.launch_stage == null ? true : contains(
        ["UNIMPLEMENTED", "PRELAUNCH", "EARLY_ACCESS", "ALPHA", "BETA",
      "GA", "DEPRECATED"], var.launch_stage)
    )
    error_message = <<EOF
    The launch stage should be one of UNIMPLEMENTED, PRELAUNCH, EARLY_ACCESS, ALPHA,
    BETA, GA, DEPRECATED.
    EOF
  }
}

variable "managed_revision" {
  description = "Whether the Terraform module should control the deployment of revisions."
  type        = bool
  nullable    = false
  default     = true
}

variable "name" {
  description = "Name used for Cloud Run service."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
}

variable "revision" {
  description = "Revision template configurations."
  type = object({
    labels                     = optional(map(string))
    name                       = optional(string)
    gen2_execution_environment = optional(bool)
    max_concurrency            = optional(number)
    max_instance_count         = optional(number)
    min_instance_count         = optional(number)
    job = optional(object({
      max_retries = optional(number)
      task_count  = optional(number)
    }), {})
    vpc_access = optional(object({
      connector = optional(string)
      egress    = optional(string)
      network   = optional(string)
      subnet    = optional(string)
      tags      = optional(list(string))
    }), {})
    timeout = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      try(var.revision.vpc_access.egress, null) == null ? true : contains(
      ["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.revision.vpc_access.egress)
    )
    error_message = "Egress should be one of ALL_TRAFFIC, PRIVATE_RANGES_ONLY."
  }
  validation {
    condition = (
      var.revision.vpc_access.network == null || (var.revision.vpc_access.network != null && var.revision.vpc_access.subnet != null)
    )
    error_message = "When providing vpc_access.network provide also vpc_access.subnet."
  }
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

variable "tag_bindings" {
  description = "Tag bindings for this service, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = map(object({
    secret = optional(object({
      name         = string
      default_mode = optional(string)
      path         = optional(string)
      version      = optional(string)
      mode         = optional(string)
    }))
    cloud_sql_instances = optional(list(string))
    empty_dir_size      = optional(string)
    gcs = optional(object({
      # needs revision.gen2_execution_environment
      bucket       = string
      is_read_only = optional(bool)
    }))
    nfs = optional(object({
      server       = string
      path         = optional(string)
      is_read_only = optional(bool)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.volumes :
      sum([for kk, vv in v : vv == null ? 0 : 1]) == 1
    ])
    error_message = "Only one type of volume can be defined at a time."
  }
}
