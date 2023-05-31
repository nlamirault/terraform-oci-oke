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

resource "oci_identity_dynamic_group" "oke_kms_cluster" {
  provider       = oci.home
  compartment_id = var.tenancy_id
  description    = "dynamic group to allow cluster to use KMS to encrypt etcd"
  matching_rule  = local.dynamic_group_rule_all_clusters
  name           = var.label_prefix == "none" ? "oke-kms-cluster" : "${var.label_prefix}-oke-kms-cluster"
  count          = var.use_cluster_encryption == true ? 1 : 0

  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [matching_rule]
  }
}

resource "oci_identity_policy" "oke_kms" {
  provider       = oci.home
  compartment_id = var.compartment_id
  description    = "policy to allow dynamic group ${var.label_prefix}-oke-kms-cluster to use KMS to encrypt etcd"
  depends_on     = [oci_identity_dynamic_group.oke_kms_cluster]
  name           = var.label_prefix == "none" ? "oke-kms" : "${var.label_prefix}-oke-kms"

  freeform_tags = var.freeform_tags

  statements     = [local.cluster_kms_policy_statement]

  count          = var.use_cluster_encryption == true ? 1 : 0
}

resource "oci_identity_policy" "oke_volume_kms" {
  provider       = oci.home
  compartment_id = var.compartment_id
  description    = "Policies for block volumes to access kms key"
  name           = var.label_prefix == "none" ? "oke-volume-kms" : "${var.label_prefix}-oke-volume-kms"
  statements     = local.oke_volume_kms_policy_statements
  
  freeform_tags = var.freeform_tags
  
  count          = var.use_node_pool_volume_encryption == true ? 1 : 0
}
