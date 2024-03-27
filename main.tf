provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "network_for_app" {
  name          = var.app_subnetwork
  ip_cidr_range = var.ip_cidr_range_webapp
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "network_for_db" {
  name                     = var.db_subnetwork
  ip_cidr_range            = var.ip_cidr_range_db
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_route" "default_compute_route" {
  name             = var.default_compute_route
  network          = google_compute_network.vpc_network.id
  dest_range       = var.default_compute_route_ip
  next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_firewall" "firewall-allow" {
  name    = var.firewall_name_allow
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_port_tcp
  }
  priority = 500

  source_tags   = var.firewall_source_tags
  source_ranges = var.firewall_source_ranges
}

resource "google_compute_firewall" "firewall-deny" {
  name    = var.firewall_name_deny
  network = google_compute_network.vpc_network.name

  deny {
    protocol = "all"
    ports    = []
  }
  source_tags   = var.firewall_source_tags
  source_ranges = var.firewall_source_ranges
}

resource "google_compute_instance" "vm-instance" {
  name         = var.ci_name
  machine_type = var.ci_machine_type
  zone         = var.ci_zone

  tags = var.ci_tags

  boot_disk {
    device_name = var.boot_disk_device_name
    initialize_params {
      image = var.image_path
      size  = var.disk_size
      type  = var.disk_type
    }
  }
  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.network_for_app.self_link
    access_config {

    }
  }
  service_account {
    email  = google_service_account.service_account.email
    scopes = var.service_account_scope
  }

  metadata_startup_script = <<-EOF
    echo "MYSQL_DATABASE_URL=jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${var.database_db_name}?createDatabaseIfNotExist=true" > .env
    echo "MYSQL_DATABASE_USERNAME=${var.database_db_name}" >> .env
    echo "MYSQL_DATABASE_PASSWORD=${random_password.password.result}" >> .env
    sudo mv .env /opt/
    sudo chown csye6225:csye6225 /opt/.env
    sudo setenforce 0
    sudo systemctl daemon-reload
    sudo systemctl restart webapp-launch.service
  EOF
}

resource "google_compute_global_address" "ps_ip_address" {
  name          = var.ps_ip_address_name
  address_type  = var.ps_ip_address_type
  purpose       = var.ps_ip_address_purpose
  network       = google_compute_network.vpc_network.self_link
  prefix_length = var.ps_ip_address_prefix_length
}

resource "google_service_networking_connection" "ps_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = var.ps_connection_service
  reserved_peering_ranges = [google_compute_global_address.ps_ip_address.name]
}

resource "google_sql_database_instance" "mysql_instance" {
  name                = "mysql-${random_string.mysql_suffix.result}"
  database_version    = var.database_version
  region              = var.database_instance_region
  deletion_protection = false
  depends_on          = [google_service_networking_connection.ps_connection]
  settings {
    tier              = var.database_instance_tier
    availability_type = var.database_availability_type
    disk_type         = var.database_disk_type
    disk_size         = 100
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_network.self_link
      enable_private_path_for_google_cloud_services = true
    }
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
  }
}

resource "google_sql_database" "mysql" {
  name     = var.database_db_name
  instance = google_sql_database_instance.mysql_instance.name
}

resource "random_password" "password" {
  length           = var.password_length
  special          = var.password_special
  min_lower        = var.password_min_lower
  min_upper        = var.password_min_upper
  min_numeric      = var.password_min_numeric
  min_special      = var.password_min_special
  override_special = var.password_override_special
}

resource "random_string" "mysql_suffix" {
  length  = var.mysql_suffix_length
  special = var.mysql_suffix_special
  upper   = var.mysql_suffix_upper
}

resource "google_sql_user" "users" {
  name     = var.database_db_name
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.password.result
  host     = google_compute_instance.vm-instance.hostname
}

resource "google_dns_record_set" "dns_record_set" {
  name = var.dns_record_name
  type = var.dns_record_type
  ttl  = var.dns_record_ttl

  managed_zone = var.managed_zone
  rrdatas      = [google_compute_instance.vm-instance.network_interface[0].access_config[0].nat_ip]
}
resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
}


resource "google_project_iam_binding" "service_account_roles_logging_admin" {
  project = var.project_id
  role    = var.logging_admin_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}
resource "google_project_iam_binding" "service_account_roles_metric_write" {
  project = var.project_id
  role    = var.metric_writer_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "service_account_roles" {
  project  = var.project_id
  for_each = toset(var.service_account_roles)
  role     = each.key

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_pubsub_topic" "verify_email" {
  name                       = var.pubsub_topic_name
  message_retention_duration = var.pubsub_retention_duration
}

resource "google_pubsub_subscription" "test_sub" {
  name                       = var.pubsub_subscriber_name
  topic                      = google_pubsub_topic.verify_email.id
  message_retention_duration = var.sub_message_retention
  retain_acked_messages      = var.retain_acked_messages
  ack_deadline_seconds       = var.ack_deadline_seconds
}
resource "random_id" "bucket_prefix" {
  byte_length = var.random_id_length
}

resource "google_storage_bucket" "storage_bucket" {
  name                        = "${random_id.bucket_prefix.hex}-${var.google_storage_bucket_name}"
  location                    = var.storage_bucket_location
  uniform_bucket_level_access = var.storage_bucket_ubla
}

resource "google_storage_bucket_object" "default" {
  name   = var.google_storage_bucket_object_name
  bucket = google_storage_bucket.storage_bucket.name
  source = var.google_storage_bucket_object_src
}
resource "google_vpc_access_connector" "connector" {
  name          = var.google_vpc_access_connector_name
  ip_cidr_range = var.google_vpc_access_connector_cidr_range
  network       = google_compute_network.vpc_network.self_link
}
resource "google_cloudfunctions2_function" "email_verification_function" {
  name        = var.google_cloudfunctions2_function_name
  location    = var.region
  description = "Email Verification function"

  build_config {
    runtime     = var.function_runtime
    entry_point = var.entry_point
    environment_variables = {
      DB_NAME                  = var.database_db_name
      DB_USERNAME              = var.database_db_name
      DB_PASSWORD              = random_password.password.result
      DB_URL                   = "jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${var.database_db_name}"
      INSTANCE_CONNECTION_NAME = google_sql_database_instance.mysql_instance.connection_name
    }
    source {
      storage_source {
        bucket = google_storage_bucket.storage_bucket.name
        object = google_storage_bucket_object.default.name
      }
    }
  }
  service_config {
    service_account_email         = google_service_account.service_account.email
    vpc_connector                 = google_vpc_access_connector.connector.id
    vpc_connector_egress_settings = var.vpc_connector_egress_settings
    environment_variables = {
      DB_NAME                  = var.database_db_name
      DB_USERNAME              = var.database_db_name
      DB_PASSWORD              = random_password.password.result
      DB_URL                   = "jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${var.database_db_name}"
      INSTANCE_CONNECTION_NAME = google_sql_database_instance.mysql_instance.connection_name
    }
  }


  event_trigger {
    trigger_region = var.region
    event_type     = var.event_trigger_event_type
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = var.event_trigger_retry_policy
  }
}