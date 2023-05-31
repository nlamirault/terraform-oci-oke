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

resource "oci_containerengine_node_pool" "nodepools" {
  for_each       = var.node_pools

  compartment_id = var.compartment_id
  cluster_id     = oci_containerengine_cluster.k8s_cluster.id

  depends_on     = [oci_containerengine_cluster.k8s_cluster]

  kubernetes_version = var.kubernetes_version
  name               = each.key

  freeform_tags = each.value["tags"]
  
  node_config_details {

    dynamic "placement_configs" {
      iterator = ad_iterator
      for_each = local.ad_names
      content {
        availability_domain = ad_iterator.value
        subnet_id           = var.cluster_subnets["workers"]
      }
    }
    nsg_ids                             = var.worker_nsgs
    is_pv_encryption_in_transit_enabled = var.enable_pv_encryption_in_transit
    kms_key_id                          = var.node_pool_volume_kms_key_id
    # allow zero-sized node pools
    size = max(0, lookup(each.value, "node_pool_size", 0))
  }

  dynamic "node_shape_config" {
    for_each = length(regexall("Flex", lookup(each.value, "shape", "VM.Standard.E4.Flex"))) > 0 ? [1] : []
    content {
      ocpus         = max(1, lookup(each.value, "ocpus", 1))
      memory_in_gbs = (lookup(each.value, "memory", 16) / lookup(each.value, "ocpus", 1)) > 64 ? (lookup(each.value, "ocpus", 1) * 64) : lookup(each.value, "memory", 16)
    }
  }

  node_metadata = {
    user_data = data.cloudinit_config.worker.rendered
  }
  
  node_source_details {
    boot_volume_size_in_gbs = lookup(each.value, "boot_volume_size", 50)
    # check is done for GPU,A1 and other shapes.In future if some other shapes or images added we need to modify
    image_id    = (var.node_pool_image_id == "none" && length(regexall("GPU|A1", lookup(each.value, "shape"))) == 0) ? (element([for source in local.node_pool_image_ids : source.image_id if length(regexall("Oracle-Linux-${var.node_pool_os_version}-20[0-9]*.*", source.source_name)) > 0], 0)) : (var.node_pool_image_id == "none" && length(regexall("GPU", lookup(each.value, "shape"))) > 0) ? (element([for source in local.node_pool_image_ids : source.image_id if length(regexall("Oracle-Linux-${var.node_pool_os_version}-Gen[0-9]-GPU-20[0-9]*.*", source.source_name)) > 0], 0)) : (var.node_pool_image_id == "none" && length(regexall("A1", lookup(each.value, "shape"))) > 0) ? (element([for source in local.node_pool_image_ids : source.image_id if length(regexall("Oracle-Linux-${var.node_pool_os_version}-aarch64-20[0-9]*.*", source.source_name)) > 0], 0)) : var.node_pool_image_id
    source_type = data.oci_containerengine_node_pool_option.node_pool_options.sources[0].source_type
  }

  node_shape = lookup(each.value, "shape", "VM.Standard.E4.Flex")

  ssh_public_key = (var.ssh_public_key != "") ? var.ssh_public_key : (var.ssh_public_key_path != "none") ? file(var.ssh_public_key_path) : ""

  # do not destroy the node pool if the kubernetes version has changed as part of the upgrade
  lifecycle {
    ignore_changes = [kubernetes_version]
  }
  dynamic "initial_node_labels" {
    for_each = lookup(each.value, "label", "") != "" ? each.value.label : {}
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }
}
