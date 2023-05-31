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

locals {

  # used by cluster
  lb_subnet = var.preferred_load_balancer == "public" ? "pub_lb" : "int_lb"

  ad_names = [
    for ad_name in data.oci_identity_availability_domains.ad_list.availability_domains :
    ad_name.name
  ]

  # dynamic group all oke clusters in a compartment
  dynamic_group_rule_all_clusters = "ALL {resource.type = 'cluster', resource.compartment.id = '${var.compartment_id}'}"

  # policy to allow dynamic group of all clusters to use kms 
  cluster_kms_policy_statement = (var.use_cluster_encryption == true) ? "Allow dynamic-group ${oci_identity_dynamic_group.oke_kms_cluster[0].name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.cluster_kms_key_id}'" : ""

  # policy to allow block volumes inside oke to use kms
  oke_volume_kms_policy_statements = (var.use_node_pool_volume_encryption == true) ? [
    "Allow service oke to use key-delegates in compartment id ${var.compartment_id} where target.key.id = '${var.node_pool_volume_kms_key_id}'",
    "Allow service blockstorage to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.node_pool_volume_kms_key_id}'"
  ] : []

  # 1. get a list of available images for this cluster
  # 2. filter by version
  # 3. if more than 1 image found for this version, pick the latest
  node_pool_image_ids = data.oci_containerengine_node_pool_option.node_pool_options.sources

}
