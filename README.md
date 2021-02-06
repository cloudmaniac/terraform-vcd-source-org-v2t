# Source Organization VDC creation for V2T demo

This Terraform configuration creates a source organization VDC and associated resources to demonstrate the value of the NSX Migration for Cloud Director tool.

## Get Started

* Download a Photon OS OVA files into the resources container: the [Photon OS 3.0 Revision 3 OVA (hw11)](https://packages.vmware.com/photon/3.0/Rev3/ova/photon-hw11-3.0-a383732.ova) works well and is only 188MB.
* Change the required variables in `terraform.tfvars`
* Change some variables in `main.tf` (e.g., for the edge IPs)

## Additional Resources

* [Download Photon OS](https://packages.vmware.com/photon/3.0/Rev3/ova/photon-hw11-3.0-a383732.ova)
