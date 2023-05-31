# Copyright (C) Nicolas Lamirault <nicolas.lamirault@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vcn_id = var.vcn_id

  endpoint_config {
    is_public_ip_enabled = var.control_plane_type == "public" ? true : false
    nsg_ids              = var.control_plane_nsgs
    subnet_id            = var.cluster_subnets["cp"]
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = var.dashboard_enabled
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    persistent_volume_config {
      defined_tags = var.defined_tags
      freeform_tags = var.freeform_tags 
      }

    service_lb_config {
      defined_tags  = var.defined_tags
      freeform_tags = var.freeform_tags 
    }

    service_lb_subnet_ids = var.load_balancer_type == "public" ? [var.cluster_subnets["public"]] : [var.cluster_subnets["internal"]]
  }
}
