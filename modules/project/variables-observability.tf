/**
 * Copyright 2024 Google LLC
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

variable "logging_data_access" {
  description = "Control activation of data access logs. Format is service => { log type => [exempted members]}. The special 'allServices' key denotes configuration for all services."
  type        = map(map(list(string)))
  nullable    = false
  default     = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.logging_data_access : [
        for kk, vv in v : contains(["DATA_READ", "DATA_WRITE", "ADMIN_READ"], kk)
      ]
    ]))
    error_message = "Log type keys for each service can only be one of 'DATA_READ', 'DATA_WRITE', 'ADMIN_READ'."
  }
}

variable "logging_exclusions" {
  description = "Logging exclusions for this project in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "log_scopes" {
  description = "Log scopes under this project."
  type = map(object({
    description    = optional(string)
    resource_names = list(string)
  }))
  nullable = false
  default  = {}
}

variable "logging_sinks" {
  description = "Logging sinks to create for this project."
  type = map(object({
    bq_partitioned_table = optional(bool, false)
    description          = optional(string)
    destination          = string
    disabled             = optional(bool, false)
    exclusions           = optional(map(string), {})
    filter               = optional(string)
    iam                  = optional(bool, true)
    type                 = string
    unique_writer        = optional(bool, true)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "project", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'project', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

variable "metric_scopes" {
  description = "List of projects that will act as metric scopes for this project."
  type        = list(string)
  default     = []
  nullable    = false
}
