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
resource "random_string" "kms_prefix" {
  length = 4
  special = false
}

resource "google_kms_key_ring" "kms_keyring" {
  name     = "keyring-${random_string.kms_prefix.result}"
  location = var.region
}

resource "google_kms_crypto_key" "storage_crypto_key" {
  name            = "storage-crypto-key"
  key_ring        = google_kms_key_ring.kms_keyring.id
  rotation_period = var.rotation_period
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "vm_crypto_key" {
  name            = "vm-crypto-key"
  key_ring        = google_kms_key_ring.kms_keyring.id
  rotation_period = var.rotation_period
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "sql_crypto_key" {
  name            = "sql-crypto-key"
  key_ring        = google_kms_key_ring.kms_keyring.id
  rotation_period = var.rotation_period
  lifecycle {
    prevent_destroy = false
  }
}

data "google_storage_project_service_account" "project_service_account" {  
}

resource "google_project_service_identity" "sql_service_identity" {
  provider = google-beta
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_binding" "storage_crypto_binding" {
  provider = google-beta
  crypto_key_id = google_kms_crypto_key.storage_crypto_key.id
  role          = var.cloudKmsEncrypDecrypt
  members       = [
    "serviceAccount:${data.google_storage_project_service_account.project_service_account.email_address}"
    ]
}

resource "google_kms_crypto_key_iam_binding" "vm_crypto_binding" {
  provider = google-beta
  crypto_key_id = google_kms_crypto_key.vm_crypto_key.id
  role          = var.cloudKmsEncrypDecrypt
  members       = [
    "serviceAccount:${var.compute_engine_service_agent}"
    ]
}

resource "google_kms_crypto_key_iam_binding" "sql_crypto_binding" {
  provider = google-beta
  crypto_key_id = google_kms_crypto_key.sql_crypto_key.id
  role          = var.cloudKmsEncrypDecrypt
  members       = [
    "serviceAccount:${google_project_service_identity.sql_service_identity.email}"
  ]
}

resource "google_sql_database_instance" "mysql_instance" {
  name                = "mysql-${random_string.mysql_suffix.result}"
  database_version    = var.database_version
  region              = var.database_instance_region
  deletion_protection = false
  depends_on          = [google_service_networking_connection.ps_connection, google_kms_crypto_key.sql_crypto_key]
  encryption_key_name = google_kms_crypto_key.sql_crypto_key.id
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
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
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
  storage_class = "REGIONAL"
  force_destroy = true
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_crypto_key.id
  }
  depends_on = [google_kms_crypto_key_iam_binding.storage_crypto_binding]
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
      MAILGUN_API_KEY = var.mailgun_api_key
    }
  }
  event_trigger {
    trigger_region = var.region
    event_type     = var.event_trigger_event_type
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = var.event_trigger_retry_policy
  }
}

resource "google_compute_region_instance_template" "vm-instance-template" {
  name         = var.ci_name
  machine_type = var.ci_machine_type
  tags         = var.ci_tags

  disk {
    source_image = var.image_path
    disk_size_gb = var.disk_size
    disk_type    = var.disk_type
    auto_delete  = true
    boot         = true
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_crypto_key.id
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
    echo "PROJECT_ID=${var.project_id}" >> .env
    echo "TOPIC_ID=${google_pubsub_topic.verify_email.id}" >> .env
    sudo mv .env /opt/
    sudo chown csye6225:csye6225 /opt/.env
    sudo setenforce 0
    sudo systemctl daemon-reload
    sudo systemctl restart webapp-launch.service
  EOF
}

resource "google_compute_health_check" "healthz-health-check" {
  name                = var.health_check_name
  description         = var.health_check_description
  timeout_sec         = var.timeout_sec
  check_interval_sec  = var.check_interval_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    port               = var.port
    port_specification = var.port_specification
    request_path       = var.request_path
  }
}

resource "google_compute_region_instance_group_manager" "webapp_server" {
  name               = "webapp-instance-group-manager"
  base_instance_name = var.base_instance_name
  region             = var.region
  version {
    instance_template = google_compute_region_instance_template.vm-instance-template.self_link
  }
  named_port {
    name = "webapp"
    port = var.port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.healthz-health-check.id
    initial_delay_sec = var.initial_delay_sec
  }
}

resource "google_compute_region_autoscaler" "compute_region_autoscaler" {
  name   = var.autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_server.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}

resource "google_compute_ssl_certificate" "namecheap_ssl_certif" {
  name        = "namecheap-ssl-cert"
  private_key = file("${var.ssl_certificate_private_key}")
  certificate = file("${var.ssl_certificate_certificate}")
}
resource "google_compute_backend_service" "default" {
  name                  = var.backend_service_name
  health_checks         = [google_compute_health_check.healthz-health-check.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "webapp"
  protocol              = "HTTP"
  log_config {
    enable = true
  }
  backend {
    group = google_compute_region_instance_group_manager.webapp_server.instance_group
  }
}

resource "google_compute_url_map" "default" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.default.id
}
resource "google_compute_target_https_proxy" "lb_default" {
  name    = "myservice-https-proxy"
  url_map = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_ssl_certificate.namecheap_ssl_certif.id
  ]
  depends_on = [
    google_compute_ssl_certificate.namecheap_ssl_certif
  ]
}

resource "google_compute_global_forwarding_rule" "default" {
  ip_protocol           = "TCP"
  name                  = "global-rule"
  target                = google_compute_target_https_proxy.lb_default.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
}

resource "google_dns_record_set" "dns_record_set" {
  name = var.dns_record_name
  type = var.dns_record_type
  ttl  = var.dns_record_ttl
  managed_zone = var.managed_zone
  rrdatas      = [google_compute_global_forwarding_rule.default.ip_address]
}
resource "google_secret_manager_secret" "DB_URL" {
  secret_id = "DB_URL"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "DB_URL_VERSION" {
  secret = google_secret_manager_secret.DB_URL.id
  secret_data = "jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${var.database_db_name}?createDatabaseIfNotExist=true"
}
resource "google_secret_manager_secret" "DB_NAME" {
  secret_id = "DB_NAME"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "DB_NAME_VERSION" {
  secret = google_secret_manager_secret.DB_NAME.id
  secret_data = var.database_db_name
}
resource "google_secret_manager_secret" "DB_PASSWORD" {
  secret_id = "DB_PASSWORD"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "DB_PASSWORD_VERSION" {
  secret = google_secret_manager_secret.DB_PASSWORD.id  
  secret_data = random_password.password.result
}
resource "google_secret_manager_secret" "KMS_KEY" {
  secret_id = "KMS_KEY"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "KMS_KEY_VERSION" {
  secret = google_secret_manager_secret.KMS_KEY.id  
  secret_data = "projects/test-cloud-csye6225/locations/us-east1/keyRings/${google_kms_key_ring.kms_keyring.name}/cryptoKeys/${google_kms_crypto_key.vm_crypto_key.name}"
}