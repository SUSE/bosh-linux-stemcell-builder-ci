# networks
resource "openstack_networking_network_v2" "bosh" {
  region         = "${var.region_name}"
  name           = "${var.env_prefix}bosh"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "bosh_subnet" {
  region           = "${var.region_name}"
  network_id       = "${openstack_networking_network_v2.bosh.id}"
  cidr             = "10.0.1${var.environment_id}.0/24"
  ip_version       = 4
  name             = "${var.env_prefix}bosh_sub"
  allocation_pools = {
    start = "10.0.1${var.environment_id}.200"
    end   = "10.0.1${var.environment_id}.254"
  }
  gateway_ip       = "10.0.1${var.environment_id}.1"
  enable_dhcp      = "true"
  dns_nameservers  = ["${compact(split(",",var.dns_nameservers))}"]
}

# router

resource "openstack_networking_router_interface_v2" "bosh_port" {
  region    = "${var.region_name}"
  router_id = "${var.outer_bosh_router_id}"
  subnet_id = "${openstack_networking_subnet_v2.bosh_subnet.id}"
}
