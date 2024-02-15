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
  description = "number of VPCs"
}