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
variable "ps_ip_address_name" {
  type    = string
  default = "ps-ip-address"
}
variable "ps_ip_address_type" {
  type    = string
  default = "INTERNAL"
}
variable "ps_ip_address_purpose" {
  type    = string
  default = "VPC_PEERING"
}
variable "ps_ip_address_prefix_length" {
  type    = number
  default = 24
}
variable "ps_connection_service" {
  type    = string
  default = "servicenetworking.googleapis.com"
}
variable "database_version" {
  type    = string
  default = "MYSQL_8_0"
}
variable "database_instance_region" {
  type    = string
  default = "us-east1"
}
variable "database_instance_tier" {
  type    = string
  default = "db-f1-micro"
}
variable "database_availability_type" {
  type    = string
  default = "REGIONAL"
}
variable "database_disk_type" {
  type    = string
  default = "PD_SSD"
}
variable "database_disk_size" {
  type    = number
  default = 100
}
variable "database_db_name" {
  type    = string
  default = "webapp"
}
variable "password_length" {
  type    = number
  default = 12
}

variable "password_special" {
  type    = bool
  default = true
}

variable "password_min_lower" {
  type    = number
  default = 2
}

variable "password_min_upper" {
  type    = number
  default = 2
}

variable "password_min_numeric" {
  type    = number
  default = 2
}

variable "password_min_special" {
  type    = number
  default = 2
}

variable "password_override_special" {
  type    = string
  default = "‘~!@#$%^&*()_-+={}[]/<>,.;?':|"
}

variable "mysql_suffix_length" {
  type    = number
  default = 8
}

variable "mysql_suffix_special" {
  type    = bool
  default = false
}

variable "mysql_suffix_upper" {
  type    = bool
  default = false
}

variable "dns_record_name" {
  type        = string
  description = "The name of the DNS record set"
}

variable "dns_record_type" {
  type        = string
  description = "The type of the DNS record set"
}

variable "dns_record_ttl" {
  type        = number
  description = "The TTL (time to live) of the DNS record set"
}

variable "managed_zone" {
  type        = string
  description = "The name of the managed zone"
}

variable "service_account_account_id" {
  type        = string
  description = "The ID of the Google Cloud service account"
}

variable "service_account_display_name" {
  type        = string
  description = "The display name of the Google Cloud service account"
}

variable "logging_admin_role" {
  type        = string
  description = "The role for logging admin permissions"
}

variable "metric_writer_role" {
  type        = string
  description = "The role for metric writer permissions"
}
variable "service_account_roles" {
  type        = list(string)
  description = "Service account Roles"
}

variable "pubsub_topic_name" {
  type = string
}

variable "pubsub_retention_duration" {
  type = string
}
variable "pubsub_subscriber_name" {
  type = string
}
variable "sub_message_retention" {
  type = string
}
variable "ack_deadline_seconds" {
  type = number
}
variable "retain_acked_messages" {
  type = bool
}
variable "random_id_length" {
  type = number
}
variable "storage_bucket_location" {
  type = string
}
variable "storage_bucket_ubla" {
  type = bool
}
variable "google_storage_bucket_name" {
  description = "The name of the Google Cloud Storage bucket"
  type        = string
}

variable "google_storage_bucket_object_name" {
  description = "The name of the object in the Google Cloud Storage bucket"
  type        = string
}

variable "google_storage_bucket_object_src" {
  type = string
}

variable "google_vpc_access_connector_name" {
  description = "The private IP address of the Google Cloud SQL database instance"
  type        = string
}

variable "google_vpc_access_connector_cidr_range" {
  description = "The CIDR range for the VPC access connector"
  type        = string
}

variable "google_cloudfunctions2_function_name" {
  description = "The name of the Cloud Function"
  type        = string
}

variable "function_runtime" {
  description = "The runtime for the Cloud Function"
  type        = string
  default     = "java17"
}

variable "entry_point" {
  description = "The entry point for the Cloud Function"
  type        = string
}
variable "vpc_connector_egress_settings" {
  description = "The egress settings for the VPC connector"
  type        = string
}
variable "event_trigger_event_type" {
  description = "The type of event that will trigger the function"
  type        = string
}
variable "event_trigger_retry_policy" {
  description = "The retry policy for the event trigger"
  type        = string
}

