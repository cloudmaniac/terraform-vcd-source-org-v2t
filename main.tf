## Terraform Initialization
terraform {
  required_version = ">= 0.13"

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.1.0"
    }
  }
}
# Configure VMware vCloud Director Provider
provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_pass
  org                  = "System"
  url                  = var.vcd_url
  max_retry_timeout    = var.vcd_max_retry_timeout
  allow_unverified_ssl = var.vcd_allow_unverified_ssl
}

# Create a new org 
resource "vcd_org" "t1" {
  name             = var.org_name
  full_name        = "Tenant 1"
  description      = "The pride of my work"
  is_enabled       = "true"
  delete_recursive = "true"
  delete_force     = "true"

  vapp_lease {
    maximum_runtime_lease_in_sec          = 0
    power_off_on_runtime_lease_expiration = false
    maximum_storage_lease_in_sec          = 0
    delete_on_storage_lease_expiration    = false
  }
}

# Create Org VDC for above org
resource "vcd_org_vdc" "t1_ovdc01" {
  depends_on = [vcd_org.t1]

  name              = var.t1_ovdc01_name
  description       = "Super dope organization VDC"
  org               = var.org_name
  allocation_model  = "AllocationVApp"
  network_pool_name = var.network_pool_name
  provider_vdc_name = var.pvdc_name

  compute_capacity {
    cpu {
      limit = 0
    }
    memory {
      limit = 0
    }
  }

  metadata = {
    Ironman   = "Tony"
    Spiderman = "Peter"
  }

  storage_profile {
    name    = "vSAN Default Storage Policy"
    limit   = 204800
    default = true
  }

  vm_quota                 = 100
  network_quota            = 100
  enabled                  = true
  enable_thin_provisioning = true
  enable_fast_provisioning = false
  delete_force             = true
  delete_recursive         = true
}

resource "vcd_edgegateway" "t1_edge01" {
  depends_on = [vcd_org_vdc.t1_ovdc01]

  org                 = var.org_name
  vdc                 = var.t1_ovdc01_name
  name                = var.t1_edge01_name
  description         = "T1 edge gateway"
  configuration       = "compact"
  distributed_routing = false
  lb_enabled          = true

  external_network {
    name = var.external_network_v_pod02_internet

    subnet {
      use_for_default_route = true

      ip_address = "10.67.29.110"
      gateway    = "10.67.29.254"
      netmask    = "255.255.255.0"

      suballocate_pool {
        start_address = "10.67.29.111"
        end_address   = "10.67.29.119"
      }
    }
  }

  external_network {
    name = var.external_network_v_pod02_service

    subnet {
      use_for_default_route = false

      ip_address = "10.67.129.110"
      gateway    = "10.67.129.254"
      netmask    = "255.255.255.0"

      suballocate_pool {
        start_address = "10.67.129.111"
        end_address   = "10.67.129.119"
      }
    }
  }
}

# Catalog
resource "vcd_catalog" "demo_catalog" {
  depends_on = [vcd_org_vdc.t1_ovdc01]

  org         = var.org_name
  name        = "catalog-tenant1"
  description = "OS templates"

  delete_force     = "true"
  delete_recursive = "true"
}

# Linux OVA
resource "vcd_catalog_item" "photon_3" {
  depends_on = [vcd_catalog.demo_catalog]

  org         = var.org_name
  catalog     = vcd_catalog.demo_catalog.name
  name        = "photon-3.0"
  description = "Photon OS 3.0 Revision 2 Update3"

  ova_path = "resources/photon-hw11-3.0-a383732.ova"

  show_upload_progress = true
}

# Org Networks
resource "vcd_network_routed" "demo_net_routed_192_168_10" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org          = var.org_name
  vdc          = var.t1_ovdc01_name
  name         = "routed_192.168.10.0"
  edge_gateway = var.t1_edge01_name

  gateway = "192.168.10.1"
  dns1    = "8.8.8.8"
  dns2    = "8.8.4.4"

  static_ip_pool {
    start_address = "192.168.10.2"
    end_address   = "192.168.10.99"
  }
}

resource "vcd_network_routed" "demo_net_routed_192_168_20" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org          = var.org_name
  vdc          = var.t1_ovdc01_name
  name         = "routed_192.168.20.0"
  edge_gateway = var.t1_edge01_name

  gateway = "192.168.20.1"
  dns1    = "8.8.8.8"
  dns2    = "8.8.4.4"

  static_ip_pool {
    start_address = "192.168.20.2"
    end_address   = "192.168.20.99"
  }
}

# vApp - three-network-tier vApp with DB, app and load balanced web app
resource "vcd_vapp" "demo_vapp" {
  depends_on = [vcd_network_routed.demo_net_routed_192_168_10, vcd_network_routed.demo_net_routed_192_168_20]

  org  = var.org_name
  vdc  = var.t1_ovdc01_name
  name = "App-XYZ"

  metadata = {
    Batman   = "Bruce Wayne"
    Superman = "Clark Kent"
  }
}

resource "vcd_vapp_org_network" "demo_vapp_org_net_routed_192_168_10" {
  org = var.org_name
  vdc = var.t1_ovdc01_name

  vapp_name        = vcd_vapp.demo_vapp.name
  org_network_name = vcd_network_routed.demo_net_routed_192_168_10.name
}

resource "vcd_vapp_org_network" "demo_vapp_org_net_routed_192_168_20" {
  org = var.org_name
  vdc = var.t1_ovdc01_name

  vapp_name        = vcd_vapp.demo_vapp.name
  org_network_name = vcd_network_routed.demo_net_routed_192_168_20.name
}

# Virtual machines creation
resource "vcd_vapp_vm" "vapp_xyz_web" {
  org = var.org_name
  vdc = var.t1_ovdc01_name

  count         = 2
  vapp_name     = vcd_vapp.demo_vapp.name
  name          = "web-0${count.index + 1}"
  description   = "Web server ${count.index + 1}"
  catalog_name  = vcd_catalog.demo_catalog.name
  template_name = vcd_catalog_item.photon_3.name
  memory        = 512
  cpus          = 1

  network {
    type               = "org"
    name               = vcd_network_routed.demo_net_routed_192_168_10.name
    ip_allocation_mode = "POOL"
  }

  customization {
    force                      = false
    change_sid                 = true
    allow_local_admin_password = true
    auto_generate_password     = false
    admin_password             = "SecuritY123!" # Doesn't work on Photon OS, need to debug, but customization fails without the parameter
    #initscript                 = "touch /tmp/romain"
  }

  accept_all_eulas = "true"
}

# Anti-affinity rule to separate VMs
resource "vcd_vm_affinity_rule" "vapp_xyz_separate_web_servers" {
  org = var.org_name
  vdc = var.t1_ovdc01_name

  name     = "Separate-VMs"
  required = true
  enabled  = true
  polarity = "Anti-Affinity"

  vm_ids = [
    vcd_vapp_vm.vapp_xyz_web[0].id,
    vcd_vapp_vm.vapp_xyz_web[1].id
  ]
}

# SNAT rule to let the VMs' traffic out
resource "vcd_nsxv_snat" "vapp_xyz_snat" {
  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway       = var.t1_edge01_name
  network_type       = "ext"
  network_name       = var.external_network_v_pod02_internet
  original_address   = "192.168.10.0/24"
  translated_address = vcd_edgegateway.t1_edge01.default_external_network_ip
}

# DNAT rules
resource "vcd_nsxv_dnat" "vapp_xyz_web_01_dnat" {
  depends_on = [vcd_vapp_vm.vapp_xyz_web]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway = var.t1_edge01_name

  network_type = "ext"
  network_name = var.external_network_v_pod02_internet

  original_address   = "10.67.29.111" ## TODO
  translated_address = vcd_vapp_vm.vapp_xyz_web[0].network.0.ip
}

resource "vcd_nsxv_dnat" "vapp_xyz_web_02_dnat" {
  depends_on = [vcd_vapp_vm.vapp_xyz_web]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway = var.t1_edge01_name

  network_type = "ext"
  network_name = var.external_network_v_pod02_internet

  original_address   = "10.67.29.112" ## TODO
  translated_address = vcd_vapp_vm.vapp_xyz_web[1].network.0.ip
}

# IP Sets
resource "vcd_nsxv_ip_set" "vapp_xyz_web_ipset_internal" {
  depends_on = [vcd_vapp_vm.vapp_xyz_web]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  name         = "webservers-internal"
  ip_addresses = ["192.168.10.2-192.168.10.3"]
}

# Gateway Firewall
resource "vcd_nsxv_firewall_rule" "rules_ingress" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  name         = "Allow Application Traffic"
  edge_gateway = var.t1_edge01_name

  source {
    ip_addresses = ["any"]
  }

  destination {
    ip_addresses = [
      "10.67.29.0/24",
    ]
  }

  service {
    protocol = "icmp"
  }

  service {
    port        = "22"
    protocol    = "tcp"
    source_port = "any"
  }

  service {
    port        = "80"
    protocol    = "tcp"
    source_port = "any"
  }
}

# Load Balancer
resource "vcd_lb_app_profile" "lb_profile" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway = var.t1_edge01_name
  name         = "http-app-profile"
  type         = "http"
}

resource "vcd_lb_service_monitor" "lb_monitor" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway = var.t1_edge01_name
  name         = "demo-http-monitor"
  interval     = "5"
  timeout      = "20"
  max_retries  = "3"
  type         = "http"
  method       = "GET"
}

resource "vcd_lb_server_pool" "lb_pool" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway        = var.t1_edge01_name
  name                = "web-servers"
  description         = "description"
  algorithm           = "round-robin"
  enable_transparency = "true"
  monitor_id          = vcd_lb_service_monitor.lb_monitor.id

  member {
    condition = "enabled"
    name      = "member1"
    #ip_address   = "${vcd_vapp_vm.demo_vm_web[0].network.0.ip}"
    ip_address   = "192.168.10.2" # TODO
    port         = 80
    monitor_port = 80
    weight       = 1
  }

  member {
    condition = "enabled"
    name      = "member2"
    #ip_address   = "${vcd_vapp_vm.demo_vm_web[1].network.0.ip}"
    ip_address   = "192.168.10.3" # TODO
    port         = 80
    monitor_port = 80
    weight       = 2
  }
}

resource "vcd_lb_virtual_server" "lb_virtual_server" {
  depends_on = [vcd_edgegateway.t1_edge01]

  org = var.org_name
  vdc = var.t1_ovdc01_name

  edge_gateway   = var.t1_edge01_name
  ip_address     = vcd_edgegateway.t1_edge01.default_external_network_ip
  name           = "demo-virtual-server"
  protocol       = "http"
  port           = 80
  app_profile_id = vcd_lb_app_profile.lb_profile.id
  server_pool_id = vcd_lb_server_pool.lb_pool.id

  provisioner "local-exec" {
    command = "echo ${vcd_edgegateway.t1_edge01.default_external_network_ip} > edge_ip.txt"
  }
}