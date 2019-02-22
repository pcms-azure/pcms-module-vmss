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

variable "resource_group" {
    type        = "string"
    default     = "${var.project}-${var.env}"
    description = "Name of the (pre-existing) resource group."
}

variable "asg" {
    type        = "string"
    default     = "${var.project}-${var.env}-${var.prefix}"
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