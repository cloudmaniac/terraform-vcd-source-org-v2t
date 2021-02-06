## Cloud Director Provider
variable "vcd_user" {}
variable "vcd_pass" {}
variable "vcd_url" {}

variable "vcd_allow_unverified_ssl" {
  default = true
}

variable "vcd_max_retry_timeout" {
  default = 60
}

## Infra
variable "pvdc_name" {}
variable "network_pool_name" {}

## Tenant configuration
variable "org_name" {}
variable "t1_ovdc01_name" {}
variable "t1_edge01_name" {}
variable "t1_edge02_name" {}
variable "external_network_v_pod02_internet" {}
variable "external_network_v_pod02_service" {}

variable "t1_edge01_internet_ip" {} # IP address of edge gateway uplink interface on the "internet" external network
variable "t1_edge02_internet_ip" {} # IP address of edge gateway uplink interface on the "internet" external network
#variable "vapp_xyz_web_dnat_ip_prefix" {}