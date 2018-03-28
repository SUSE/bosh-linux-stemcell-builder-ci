

# key pairs
resource "openstack_compute_keypair_v2" "bosh" {
  region     = "${var.region_name}"
  name       = "bosh${var.keypair_suffix}"
  public_key = "${replace("${file("bosh.pub")}","\n","")}"
}

# floating ips
resource "openstack_networking_floatingip_v2" "bosh" {
  region = "${var.region_name}"
  pool   = "${var.ext_net_name}"
}
