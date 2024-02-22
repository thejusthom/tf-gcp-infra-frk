variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "csye-6225-414307"
}

variable "region" {
  description = "The region where the resources will be provisioned"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where the resources will be provisioned"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "The VPC name"
  type        = string
  default     = "vpc-network"
}

variable "ip_cidr_range_webapp" {
  description = "ip_cidr_range_webapp"
  type        = string
  default     = "10.0.0.0/24"
}

variable "ip_cidr_range_db" {
  description = "ip_cidr_range_db"
  type        = string
  default     = "10.0.1.0/24"
}

variable "default_compute_route_ip" {
  description = "default-compute-route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_subnetwork" {
  description = "name of app subnetwork"
  type        = string
  default     = "webapp"
}

variable "db_subnetwork" {
  description = "name of db subnetwork"
  type        = string
  default     = "db"
}

variable "default_compute_route" {
  description = "name of db default compute route"
  type        = string
  default     = "default-compute-route"
}

variable "vpc_count" {
  type        = string
  description = "number of VPCs"
}

variable "routing_mode" {
  type        = string
  description = "routing mode"
}

variable "next_hop_gateway" {
  type        = string
  description = "value"
}

variable "firewall_name_allow" {
  type        = string
  description = "Firewall name"
}

variable "firewall_name_deny" {
  type        = string
  description = "Firewall name"
}

variable "allowed_port_tcp" {
  type        = list(string)
  description = "Allowed TCP Ports"
}
variable "firewall_source_tags" {
  type = list(string)
}
variable "firewall_source_ranges" {
  type = list(string)
}
variable "ci_name" {
  type        = string
  description = "Name of the VM"
}

variable "ci_machine_type" {
  type        = string
  description = "Compute Instance Machine Type"
}

variable "ci_zone" {
  type        = string
  description = "Compute Instance Zone"
}

variable "ci_tags" {
  type        = list(string)
  description = "VM Tags"

}

variable "boot_disk_device_name" {
  type        = string
  description = "Boot Disk Device Name"
}

variable "image_path" {
  type        = string
  description = "Image Path"
}

variable "disk_size" {
  type        = number
  description = "Size of disk"

}

variable "disk_type" {
  type        = string
  description = "Disk Type"
}

variable "service_account_email" {
  type        = string
  description = "Service account email"
}

variable "service_account_scope" {
  type        = list(string)
  description = "Service account scope"
}