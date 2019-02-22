variable "project" {
    type        = "string"
    default     = "pcms-microsoft-non-prod"
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

variable "vmsize" {
    type        = "string"
    default     = "Standard_D4s_v3"
}

variable "accelerated" {
   default      =   true
   description  = "Accelerated networking for Linux.  Set to false for VM sizes that do not support."
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

variable "resource_group" {
    type        = "string"
    default     = ""
    description = "Name of the (pre-existing) resource group."
}

variable "asg" {
    type        = "string"
    default     = ""
    description = "Name of the (pre-existing) application security group."
}

variable "loc" {
    type        = "string"
    default     = "westeurope"
    description = "Azure region shortname."
}

variable "tags" {
    type        = "map"
    default     = {}
    description = "Map of tag name:value pairs."
}

variable "emails" {
    type        = "list"
    default     = []
    description = "L:ist of email addresses for the auto-scaling actions."
}