variable "project" {
    type        = "string"
    default     = "pcms-contoso-non-prod"
    description = "PCMS project identifier, e.g. pcms-<customername>-non-prod*"
}

variable "environment_name" {
    type        = "string"
    default     = "dev2"
    description = "PCMS project identifier, e.g.prod, dev2"
}

variable "prefix" {
    type        = "string"
    default     = "myfirstvmss"
    description = "Prefix for the VMSS names."
}

variable "env_resource_group" {
    type        = "string"
    default     = ""
    description = "Name of the (pre-existing) resource group."
}

variable "subnet_id" {
    type        = "string"
    description = "Resource ID of the subnet."
}

variable "asg_id" {
    type        = "string"
    description = "ID of the application security group."
}

variable "vmsize" {
    description = "VM size, from `az vm list-sizes --location westeurope --output table`"
    type        = "string"
    // default     = "Standard_D4s_v3"
    default     = "Standard_B1s"
}

variable "accelerated" {
   description  = "Accelerated networking for Linux.  Set to false for VM sizes that do not support."
   default      =  false
   // default      =  true
}

variable "vmcount" {
    type        = "string"
    default     = 2
}

variable "vmmin" {
    type        = "string"
    default     = 2
}

variable "vmmax" {
    type        = "string"
    default     = 10
}

variable "lb_port" {
    type        = "map"
    description = "List of front end to backend ports.  Will use in both load balancer rules and health probes. Frontend, protocol, backend."
    default     = {
                    http = ["80", "Tcp", "80"]
                  }
}

variable "image_id" {
    type        = "string"
    default     = ""
    description = "Resource ID of packer build image, usually from data.azurerm_image. Will default to platform image of Ubuntu 16.04 if unspecified."
}

variable "tags" {
    type        = "map"
    default     = {}
    description = "Map of tag name:value pairs. Will default using local to that of the resource group."
}

variable "emails" {
    type        = "list"
    default     = []
    description = "L:ist of email addresses for the auto-scaling actions."
}