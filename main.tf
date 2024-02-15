provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  count                           = var.vpc_count
  name                            = "${var.vpc_name}-${count.index}"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "network_for_app" {
  count         = var.vpc_count
  name          = count.index < 1 ? var.app_subnetwork : "${var.app_subnetwork}-${count.index}"
  ip_cidr_range = var.ip_cidr_range_webapp
  region        = var.region
  network       = element(google_compute_network.vpc_network[*].id, count.index)
}

resource "google_compute_subnetwork" "network_for_db" {
  count         = var.vpc_count
  name          = count.index < 1 ? var.db_subnetwork : "${var.db_subnetwork}-${count.index}"
  ip_cidr_range = var.ip_cidr_range_db
  region        = var.region
  network       = element(google_compute_network.vpc_network[*].id, count.index)
}

resource "google_compute_route" "default_compute_route" {
  count            = var.vpc_count
  name             = count.index < 1 ? var.default_compute_route : "${var.default_compute_route}-${count.index}"
  network          = element(google_compute_network.vpc_network[*].id, count.index)
  dest_range       = var.default_compute_route_ip
  next_hop_gateway = "default-internet-gateway"
}