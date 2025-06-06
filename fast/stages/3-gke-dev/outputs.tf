# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "cluster_ids" {
  description = "Cluster ids."
  value = {
    for k, v in module.gke-cluster : k => v.id
  }
}

output "clusters" {
  description = "Cluster resources."
  sensitive   = true
  value       = module.gke-cluster
}

output "project_id" {
  description = "GKE project id."
  value       = module.gke-project-0.project_id
}

resource "google_storage_bucket_object" "version" {
  count  = fileexists("fast_version.txt") ? 1 : 0
  bucket = var.automation.outputs_bucket
  name   = "versions/3-${var.stage_config.name}-version.txt"
  source = "fast_version.txt"
}
