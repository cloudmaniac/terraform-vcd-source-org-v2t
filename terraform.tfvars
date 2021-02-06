## Cloud Director Provider
vcd_user                 = "administrator"
vcd_pass                 = "VMware1!"
vcd_url                  = "https://cloud.emea.cluster.net/api"
vcd_max_retry_timeout    = "60"
vcd_allow_unverified_ssl = "true"

## Infra
network_pool_name = "np-pod02-vxlan"
pvdc_name         = "pvdc-pod02-v"

## Organization
org_name                          = "t1"
t1_ovdc01_name                    = "t1-ovdc01"
t1_edge01_name                    = "t1-demo-edge01"
t1_edge02_name                    = "t1-demo-edge02"
external_network_v_pod02_internet = "ext-v-pod02-internet"
external_network_v_pod02_service  = "ext-v-pod02-service"

t1_edge01_internet_ip = "10.67.29.111"
t1_edge02_internet_ip = "10.67.129.121"