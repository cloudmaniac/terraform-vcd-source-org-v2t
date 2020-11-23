terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.13"
}