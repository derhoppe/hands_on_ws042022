variable "location" {
    description = "Location of the resources"
    default     = "eastus"
}

variable "location_short" {
    description = "Shortname for location eg AZEUW for Azure West Europe"
    default     = "AZEU1"
}

variable "environment" {
    description = "Environment like DEV, QAS, PRD"
    default = "DEV"
}
