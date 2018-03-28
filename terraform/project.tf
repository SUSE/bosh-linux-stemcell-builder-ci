# TODO add provider config like in environment/

variable "region_name" {
  description = "OpenStack region name"
}

variable "concourse_secgroup_id" {
  description = "OpenStack region name"
  default = "bosh-concourse"
}

# security group
resource "openstack_networking_secgroup_v2" "secgroup" {
  region = "${var.region_name}"
  name = "bosh"
  description = "BOSH Test Envs Security Group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  remote_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_4" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_5" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 25555
  port_range_max = 25555
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_6" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 6868
  port_range_max = 6868
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_7" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 53
  port_range_max = 53
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_8" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  port_range_min = 53
  port_range_max = 53
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

# TODO necessary?

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_9" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 4568
  port_range_max = 4568
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_10" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  remote_group_id = "${var.concourse_secgroup_id}"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_11" {
  region = "${var.region_name}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  remote_group_id = "${var.concourse_secgroup_id}"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup.id}"
}
