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
  next_hop_gateway = "default-internet-gateway"
}

