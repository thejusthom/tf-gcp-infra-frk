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
  name          = var.db_subnetwork
  ip_cidr_range = var.ip_cidr_range_db
  region        = var.region
  network       = google_compute_network.vpc_network.id
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
    email  = var.service_account_email
    scopes = var.service_account_scope
  }
}